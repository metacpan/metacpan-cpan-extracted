# ABSTRACT: Sync karr board with remote

package App::karr::Cmd::Sync;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use feature 'say';
use MooX::Options (
    usage_string => 'USAGE: karr sync [--push] [--pull] [--prune] [--accept-foreign-board]',
);
use App::karr::Role::BoardAccess;

with 'App::karr::Role::BoardAccess';


option push => ( is => 'ro', default => 0, doc => 'Push refs to remote' );
option pull => ( is => 'ro', default => 0, doc => 'Pull refs from remote' );
option prune => (
    is      => 'ro',
    default => 0,
    doc     => 'Accept a pull that deletes every remaining board ref',
);
option accept_foreign_board => (
    is      => 'ro',
    default => 0,
    doc     => 'Accept a pull whose remote presents a different board identity',
);

sub execute {
    my ( $self, $args, $data ) = @_;

    my $git = $self->git;

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
        print STDERR "Pulling refs/karr/ from remote...\n" unless $self->quiet;
        # --prune is the one place that may reconcile the board down to
        # nothing, and --accept-foreign-board the one place that may adopt a
        # remote whose board identity is not this board's; everywhere else
        # App::karr::Git refuses and says so (#82, #95).
        $git->pull( undef,
            accept_wipe    => $self->prune,
            accept_foreign => $self->accept_foreign_board )
            or die "Pull failed: " . ( $git->last_error // 'unknown error' ) . "\n";
    }

    unless ($pull_only) {
        print STDERR "Pushing refs/karr/ to remote...\n" unless $self->quiet;
        $git->push
            or die "Push failed: " . ( $git->last_error // 'unknown error' ) . "\n";
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

version 0.500

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

=item * C<--prune>

Accepts a reconciliation that would delete every remaining board ref. Any
other command refuses that and stops, because "the remote deliberately
dropped the board" and "the remote is empty for the wrong reason" -- a
re-created origin, an edited remote URL, a rolled-back hosting-side restore --
look exactly alike from here. Use it to let a C<karr destroy> performed on
another clone take effect on this one; check C<git remote -v> first.

=item * C<--accept-foreign-board>

Accepts a pull whose remote presents a different board identity than the one
this clone has been syncing with. Any other pull refuses that before
reconciling anything, because a swapped remote -- a re-initialised origin, an
edited remote URL, a stale clone pointed at the wrong repository -- would
otherwise replace this board with a stranger's, silently and totally. Use it
when the remote's board really is the one you want from now on; check
C<git remote -v> first.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Board>,
L<App::karr::Cmd::Backup>, L<App::karr::Cmd::Restore>

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
