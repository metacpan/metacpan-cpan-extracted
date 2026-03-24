# ABSTRACT: Sync karr board with remote

package App::karr::Cmd::Sync;
our $VERSION = '0.102';
use Moo;
use MooX::Cmd;
use feature 'say';
use MooX::Options (
    usage_string => 'USAGE: karr sync [--push] [--pull]',
);
use App::karr::Role::BoardAccess;

with 'App::karr::Role::BoardAccess';


option push => ( is => 'ro', default => 0, doc => 'Push refs to remote' );
option pull => ( is => 'ro', default => 0, doc => 'Pull refs from remote' );

sub execute {
    my ( $self, $args, $data ) = @_;

    require App::karr::Git;
    my $git = App::karr::Git->new( dir => $self->git_root->stringify );

    unless ( $git->is_repo ) {
        say "Not a git repository. Skipping sync.";
        return;
    }

    my $email = $git->git_user_email;
    my $name = $git->git_user_name;
    unless ($email) {
        say q(No git user.email configured. Run: git config --global user.email 'you@example.com');
        return;
    }

    say "User: $name <$email>";

    my $push_only = $self->push && !$self->pull;
    my $pull_only = $self->pull && !$self->push;

    unless ($push_only) {
        say "Pulling refs/karr/ from remote...";
        $git->pull;
    }

    unless ($pull_only) {
        say "Pushing refs/karr/ to remote...";
        $git->push;
    }

    say "Done.";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Sync - Sync karr board with remote

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    karr sync
    karr sync --pull
    karr sync --push

=head1 DESCRIPTION

Synchronises the C<refs/karr/*> namespace with the configured remote. Without
flags it fetches the remote ref state and then pushes the local ref state back,
pruning deleted refs so destructive restore operations can be mirrored
correctly.

=head1 OPTIONS

=over 4

=item * C<--pull>

Only fetches remote C<refs/karr/*>.

=item * C<--push>

Only pushes local C<refs/karr/*> state to the configured remote.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Board>,
L<App::karr::Cmd::Backup>, L<App::karr::Cmd::Restore>

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
