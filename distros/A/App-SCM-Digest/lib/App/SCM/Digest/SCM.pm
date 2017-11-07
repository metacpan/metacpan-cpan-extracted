package App::SCM::Digest::SCM;

use strict;
use warnings;

sub is_usable
{
    die "Not implemented.";
}

sub clone
{
    die "Not implemented.";
}

sub open_repository
{
    die "Not implemented.";
}

sub pull
{
    die "Not implemented.";
}

sub branches
{
    die "Not implemented.";
}

sub branch
{
    die "Not implemented.";
}

sub checkout
{
    die "Not implemented.";
}

sub commits_from
{
    die "Not implemented.";
}

sub has
{
    die "Not implemented.";
}

sub show
{
    die "Not implemented.";
}

sub show_all
{
    die "Not implemented.";
}

1;

__END__

=head1 NAME

App::SCM::Digest::SCM

=head1 DESCRIPTION

Interface for the operations required of a SCM by
L<App::SCM::Digest>.

=head1 INTERFACE METHODS

=over 4

=item B<new>

Constructor for the implementation.  If the implementation is not
supported, this call should die.

=item B<clone>

Takes a repository URL and a directory name as its arguments.  Clones
(i.e. checks out a local copy of) the repository into the specified
directory.

=item B<open_repository>

Takes a repository path as its single argument.  "Opens" the
repository, typically by way of C<chdir>.  Once a repository is
opened, subsequent method calls will operate on that repository, until
C<open> is called again or C<chdir> is executed in some other context.

=item B<is_usable>

Returns a boolean indicating whether other operations may be performed
on this repository.  Should be called immediately after calling
C<open_repository>, and prior to calling any other repository-specific
method.

=item B<pull>

Pulls pending updates from the remote repository.

=item B<branches>

Returns an arrayref mapping from branch name to the last commit
received for that branch.

=item B<branch>

Returns the currently-checked-out branch name.

=item B<checkout>

Takes a branch name as its single argument, and checks out that
branch.

=item B<commits_from>

Takes a branch name and a commit ID as its arguments, and returns an
arrayref containing all commits on that branch that were received
after the given commit.  The arrayref is in order from least to most
recent, i.e. the last element of the arrayref contains the most recent
commit.

=item B<has>

Takes a commit ID as its single argument.  Returns a boolean
indicating whether the commit is present in the history for the
current branch.

=item B<show>

Takes a commit ID as its single argument.  Returns the basic details
of the commit as an arrayref of strings.  This typically contains
details like commit time, author, and commit message.

=item B<show_all>

Takes a commit ID as its single argument.  Returns the basic details
of the commit, plus the diff of the commit, as an arrayref of strings.

=back

=cut
