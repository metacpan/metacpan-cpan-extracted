# ABSTRACT: Ref-backed board storage for karr

package App::karr::BoardStore;
our $VERSION = '0.401';
use Moo;
use Path::Tiny qw( path );
use YAML::XS qw( DumpFile LoadFile );
use Time::Piece;
use App::karr::Config;

has git => (
    is       => 'ro',
    required => 1,
);


sub board_exists {
    my ($self) = @_;
    return $self->git->ref_exists('refs/karr/config')
        || $self->git->ref_exists('refs/karr/meta/next-id');
}

sub load_config_overrides {
    my ($self) = @_;
    my $data = $self->git->read_config_ref;
    return ref $data eq 'HASH' ? $data : {};
}

sub load_config {
    my ($self) = @_;
    return App::karr::Config->effective_config( $self->load_config_overrides );
}

sub effective_config {
    my ($self) = @_;
    return $self->{_effective_config} //= $self->load_config;
}

sub all_status_names {
    my ($self) = @_;
    my $ec = $self->effective_config;
    return map { ref $_ ? $_->{name} : $_ } @{$ec->{statuses} // []};
}


sub status_requires_claim {
    my ($self, $status_name) = @_;
    return App::karr::Config->from_merged( $self->effective_config )
        ->status_requires_claim($status_name);
}


sub is_terminal_status {
    my ($self, $status_name) = @_;
    return App::karr::Config->is_terminal_status($status_name);
}


sub save_config {
    my ( $self, $effective ) = @_;
    my $defaults = App::karr::Config->default_config;
    my $overrides = _diff_hashes( $defaults, $effective );
    $overrides->{version} = $effective->{version} // 1;
    delete $self->{_effective_config};  # invalidate cache
    return $self->git->write_config_ref($overrides);
}

sub peek_next_id {
    my ($self) = @_;
    return $self->git->read_next_id_ref;
}

sub allocate_next_id {
    my ($self) = @_;
    my $id = $self->peek_next_id;
    $self->git->write_next_id_ref( $id + 1 );
    return $id;
}

sub set_next_id {
    my ( $self, $next_id ) = @_;
    return $self->git->write_next_id_ref($next_id);
}

sub load_tasks {
    my ($self) = @_;
    my @ids = $self->git->list_task_refs;
    return map { $self->git->load_task_ref($_) } @ids;
}

sub find_task {
    my ( $self, $id ) = @_;
    return $self->git->load_task_ref($id);
}

sub save_task {
    my ( $self, $task ) = @_;
    # Bump `updated` centrally on every mutation of an existing task, so
    # move/edit/pick/handoff/archive get a fresh timestamp for free. A brand
    # new task keeps its own `updated` (== created); the restore/import path in
    # serialize_from bypasses this via git->save_task_ref to preserve stamps.
    my $ref = "refs/karr/tasks/" . $task->id . "/data";
    $task->updated( gmtime->datetime . 'Z' ) if $self->git->ref_exists($ref);
    return $self->git->save_task_ref($task);
}

sub delete_task {
    my ( $self, $id ) = @_;
    return $self->git->delete_ref("refs/karr/tasks/$id/data");
}

sub list_karr_refs {
    my ($self) = @_;
    return $self->git->list_refs('refs/karr/');
}

sub delete_all_karr_refs {
    my ($self) = @_;
    return $self->git->delete_refs('refs/karr/');
}

sub materialize_to {
    my ( $self, $board_dir ) = @_;
    $board_dir = path($board_dir);
    my $tasks_dir = $board_dir->child('tasks');
    $board_dir->mkpath;
    $tasks_dir->mkpath;

    DumpFile( $board_dir->child('config.yml')->stringify, $self->load_config );

    for my $old_file ( $tasks_dir->children(qr/\.md$/) ) {
        $old_file->remove;
    }

    for my $task ( $self->load_tasks ) {
        $task->save($tasks_dir);
    }

    return $board_dir;
}

sub file_view_gitignore_entries {
    # The disposable file view materialize_to writes: config.yml + tasks/*.md.
    # These must always be gitignored -- refs/karr/* is the canonical state and
    # the view is never committed. Mirror the exact names used by materialize_to.
    return ( 'tasks/', 'config.yml' );
}

sub ensure_gitignore {
    my ( $self, $board_dir ) = @_;
    $board_dir = path($board_dir);
    my $gitignore = $board_dir->child('.gitignore');

    my @entries  = $self->file_view_gitignore_entries;
    my $existing = $gitignore->exists ? $gitignore->slurp_utf8 : '';

    # Line-exact presence (whitespace-insensitive), so we never duplicate an
    # entry -- or our header -- that is already there.
    my %present;
    for my $line ( split /\n/, $existing ) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        $present{$line} = 1 if length $line;
    }

    my @missing = grep { !$present{$_} } @entries;
    return () unless @missing;

    my $header         = '# karr materialized task view -- never commit';
    my $header_present = $present{$header} ? 1 : 0;

    # Idempotent append that keeps the existing file intact: terminate a
    # dangling last line, separate a fresh karr block with a blank line, and
    # only emit the header when starting one.
    my $append = '';
    if ( length $existing ) {
        $append .= "\n" unless $existing =~ /\n\z/;
        $append .= "\n" unless $header_present;
    }
    $append .= "$header\n" unless $header_present;
    $append .= "$_\n" for @missing;

    $gitignore->append_utf8($append);
    return @missing;
}

sub serialize_from {
    my ( $self, $board_dir ) = @_;
    $board_dir = path($board_dir);
    my $config_file = $board_dir->child('config.yml');
    if ( $config_file->exists ) {
        my $config = LoadFile( $config_file->stringify );
        delete $config->{next_id};
        $self->save_config($config);
    }

    my %seen;
    my $tasks_dir = $board_dir->child('tasks');
    if ( $tasks_dir->exists ) {
        require App::karr::Task;
        for my $file ( $tasks_dir->children(qr/\.md$/) ) {
            my $task = App::karr::Task->from_file($file);
            # Restore/import path: persist verbatim so the original `updated`
            # timestamps survive, even when overwriting pre-existing refs.
            $self->git->save_task_ref($task);
            $seen{ $task->id } = 1;
        }
    }

    for my $id ( $self->git->list_task_refs ) {
        next if $seen{$id};
        $self->delete_task($id);
    }

    # Bootstrap fix (#30): import does not require a pre-existing board, so on a
    # fresh repo meta/next-id is missing and a following `karr create` would
    # re-allocate an already-imported id. Seed next-id past the highest imported
    # id when the stored next-id is missing or stale, but never lower a next-id
    # that is already ahead of the view (an existing healthy board is untouched).
    if (%seen) {
        my ($max_id) = sort { $b <=> $a } keys %seen;
        $self->set_next_id( $max_id + 1 ) if $self->peek_next_id <= $max_id;
    }

    return 1;
}

sub snapshot {
    my ($self) = @_;
    my %snapshot;
    for my $ref ( $self->list_karr_refs ) {
        $snapshot{$ref} = $self->git->read_ref($ref);
    }
    return {
        version => 1,
        refs => \%snapshot,
    };
}

sub restore_snapshot {
    my ( $self, $snapshot ) = @_;
    my $refs = $snapshot->{refs} || {};
    $self->delete_all_karr_refs;
    for my $ref ( sort keys %$refs ) {
        $self->git->write_ref( $ref, $refs->{$ref} );
    }
    return 1;
}

sub _diff_hashes {
    my ( $defaults, $effective ) = @_;
    my %diff;
    for my $key ( keys %{ $effective // {} } ) {
        next if $key eq 'next_id';
        my $have_default = exists $defaults->{$key};
        my $default = $defaults->{$key};
        my $value   = $effective->{$key};

        if ( ref($value) eq 'HASH' && ref($default) eq 'HASH' ) {
            my $nested = _diff_hashes( $default, $value );
            $diff{$key} = $nested if keys %$nested;
        } elsif ( !$have_default || !_same_value( $default, $value ) ) {
            $diff{$key} = $value;
        }
    }
    return \%diff;
}

sub _same_value {
    my ( $left, $right ) = @_;
    return 0 if ref($left) ne ref($right);
    if ( ref($left) eq 'HASH' ) {
        return 0 unless keys(%$left) == keys(%$right);
        for my $key ( keys %$left ) {
            return 0 unless exists $right->{$key};
            return 0 unless _same_value( $left->{$key}, $right->{$key} );
        }
        return 1;
    }
    if ( ref($left) eq 'ARRAY' ) {
        return 0 unless @$left == @$right;
        for my $i ( 0 .. $#$left ) {
            return 0 unless _same_value( $left->[$i], $right->[$i] );
        }
        return 1;
    }
    return ( defined $left ? $left : '' ) eq ( defined $right ? $right : '' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::BoardStore - Ref-backed board storage for karr

=head1 VERSION

version 0.401

=head1 SYNOPSIS

    my $store = App::karr::BoardStore->new( git => $git );
    my $config = $store->load_config;
    my $id = $store->allocate_next_id;
    my @tasks = $store->load_tasks;

=head1 DESCRIPTION

L<App::karr::BoardStore> treats C<refs/karr/*> as the canonical board state.
It can merge sparse config overrides with code defaults, allocate numeric task
ids through a dedicated metadata ref, and materialize or serialize temporary
board views for command handlers that still work with files internally.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Git>, L<App::karr::Task>,
L<App::karr::Config>

=head2 all_status_names

Returns a list of all status names from the effective config.

    my @statuses = $store->all_status_names;

=head2 status_requires_claim

Returns true if the given status requires a claim.

    if ($store->status_requires_claim('in-progress')) {
        # must use --claim to move here
    }

=head2 is_terminal_status

Returns true if the status is terminal (done or archived).

    unless ($store->is_terminal_status($task->status)) {
        # task is still active
    }

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
