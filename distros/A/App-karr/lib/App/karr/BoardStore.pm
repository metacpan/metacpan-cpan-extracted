# ABSTRACT: Ref-backed board storage for karr

package App::karr::BoardStore;
our $VERSION = '0.102';
use Moo;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use YAML::XS qw( DumpFile LoadFile );
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
    my $defaults = App::karr::Config->default_config;
    my $overrides = $self->load_config_overrides;
    return _merge_hashes( $defaults, $overrides );
}

sub save_config {
    my ( $self, $effective ) = @_;
    my $defaults = App::karr::Config->default_config;
    my $overrides = _diff_hashes( $defaults, $effective );
    $overrides->{version} = $effective->{version} // 1;
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
            $self->save_task($task);
            $seen{ $task->id } = 1;
        }
    }

    for my $id ( $self->git->list_task_refs ) {
        next if $seen{$id};
        $self->delete_task($id);
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

sub temp_board_dir {
    my ($self) = @_;
    my $dir = path( tempdir( CLEANUP => 1 ) );
    return $self->materialize_to($dir);
}

sub _merge_hashes {
    my ( $base, $overrides ) = @_;
    my %merged = %{$base // {}};
    for my $key ( keys %{ $overrides // {} } ) {
        if ( ref($merged{$key}) eq 'HASH' && ref($overrides->{$key}) eq 'HASH' ) {
            $merged{$key} = _merge_hashes( $merged{$key}, $overrides->{$key} );
        } else {
            $merged{$key} = $overrides->{$key};
        }
    }
    return \%merged;
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

version 0.102

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

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-karr/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
