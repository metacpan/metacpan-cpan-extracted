# ABSTRACT: Role providing minimal board discovery and config access

package App::karr::Role::BoardDiscovery;
our $VERSION = '0.301';
use Moo::Role;
use Path::Tiny;
use Carp qw( croak );


has git_root => (
    is  => 'lazy',
    isa => sub {
        die "git_root must be a Path::Tiny object" unless eval { $_[0]->isa('Path::Tiny') };
    },
);

has store => (
    is => 'lazy',
);

has git => (
    is => 'lazy',
);

has config => (
    is => 'lazy',
);

has board_dir => (
    is      => 'lazy',
    builder => sub { $_[0]->git_root },
);

# Actor role for the activity log identity: 'user' (default) or 'agent'.
# Carried to nested karr calls via the KARR_ROLE env var (foundation sets
# 'agent'); a --role option on a command overrides this attribute.
has role => (
    is      => 'lazy',
    builder => sub { $ENV{KARR_ROLE} || 'user' },
);

sub _build_git_root {
    my ($self) = @_;
    require App::karr::Git;

    my $start = $self->can('has_dir') && $self->has_dir
        ? path( $self->dir )->absolute
        : path('.')->absolute;

    while (1) {
        my $git = App::karr::Git->new( dir => $start->stringify );
        my $root = $git->repo_root;
        return $root if $root;
        last if $start->is_rootdir;
        $start = $start->parent;
    }
    croak "Not a git repository. karr requires Git.\n";
}

sub _build_store {
    my ($self) = @_;
    require App::karr::Git;
    require App::karr::BoardStore;
    my $git = App::karr::Git->new( dir => $self->git_root->stringify );
    return App::karr::BoardStore->new( git => $git );
}

sub _build_git {
    my ($self) = @_;
    return $self->store->git;
}

sub _build_config {
    my ($self) = @_;
    my $merged = $self->store->effective_config;
    require App::karr::Config;
    return App::karr::Config->from_merged($merged);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::BoardDiscovery - Role providing minimal board discovery and config access

=head1 VERSION

version 0.301

=head1 DESCRIPTION

This role provides the minimal interface for discovering the board's Git
repository and BoardStore. It provides:

=over 4

=item * C<git_root> — path to the Git repository (walks up from C<dir> or CWD)

=item * C<store> — L<App::karr::BoardStore> instance backed by the Git repo

=item * C<git> — shortcut to C<< $self->store->git >> (lazy)

=item * C<config> — shortcut to C<< $self->store->effective_config >> (lazy)

=back

Commands that need the sync lifecycle should also compose
L<App::karr::Role::SyncLifecycle>.

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
