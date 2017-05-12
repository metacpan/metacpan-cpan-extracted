package Daizu::Publish::Editor;
use warnings;
use strict;

use SVN::Delta;
use base 'SVN::Delta::Editor';

use Carp::Assert qw( assert DEBUG );
use Daizu::Util qw(
    like_escape
);

=head1 NAME

Daizu::Publish::Editor - Subversion editor for creating publishing jobs

=head1 DESCRIPTION

This class provides a Subversion editor which collects information about
which files have changed, and what kind of changes were made to them
(changed content, new properties, etc.).  This information can then be
used to create a 'publishing job' which dictates what work needs to be
done to bring the websites up to date.

=head1 BATONS

Directory and file batons are a reference to a hash which can contain the
following keys:

=over

=item guid_id

Reference to entry in C<file_guid> table.

=item action

Type of change made to a directory or the actual content of a file.
Can be 'A' for added, 'M' for content modified.  If it isn't present no
actual changes have been made to the content (although there may still
be changes to properties).

=item props

A reference to a hash where the keys are property names and the values
are either 'M' if a new property has been added or an existing one
changed, or 'D' if an existing property has been deleted.  Only present
if any property modifications have been made.  Doesn't include special
'entry' properties (those with names starting with C<svn:entry:>).

=back

The file/directory batons are C<undef> for directories which aren't stored
in the working copy, but are further up the directory hierarchy, such
as 'trunk'.

=cut

sub delete_entry
{
    my ($self, $path) = @_;
    my $db = $self->{db};
    my $branch_path = $self->{branch_path};

    my $sth;
    if (length($path) <= length($branch_path)) {
        # If this is the branch directory or something above it, then
        # all the files which were present in the base revision should be
        # deleted.
        assert($path eq substr($branch_path, 0, length($path))) if DEBUG;
        $sth = $db->prepare(q{
            select guid_id
            from file_path
            where branch_id = ?
              and first_revnum <= ?
              and last_revnum >= ?
        });
        $sth->execute($self->{branch_id}, $self->{start_rev},
                      $self->{start_rev});
    }
    else {
        # Delete a file or directory, and anything which was inside it.
        assert($branch_path eq substr($path, 0, length($branch_path))) if DEBUG;
        $path = substr($path, length($branch_path) + 1);
        $sth = $db->prepare(q{
            select guid_id
            from file_path
            where branch_id = ?
              and first_revnum <= ?
              and last_revnum >= ?
              and (path = ? or path like ?)
        });
        $sth->execute($self->{branch_id}, $self->{start_rev},
                      $self->{start_rev}, $path, like_escape($path) . '/%');
    }

    my $found_one;
    my $changes = $self->{changes};
    while (my ($guid_id) = $sth->fetchrow_array) {
        assert(!exists $changes->{$guid_id}) if DEBUG;
        $changes->{$guid_id} = { _status => 'D' };
        $found_one = 1;
    }
    assert($found_one) if DEBUG;
}

sub add_file
{
    my ($self, $path) = @_;
    my $branch_path = $self->{branch_path};
    return undef unless length($path) > length($branch_path);

    assert($branch_path eq substr($path, 0, length($branch_path))) if DEBUG;
    $path = substr($path, length($branch_path) + 1);
    my $guid_id = $self->_file_guid_id($path);

    my $changes = $self->{changes};
    if (exists $changes->{$guid_id}) {
        # The file has been deleted and then re-added, which we treat as
        # being a modification with a change to the path.
        my $change = $changes->{$guid_id};
        assert($change->{_status} eq 'D') if DEBUG;
        $change->{_status} = 'M';
        $change->{_path} = undef;
    }
    else {
        $changes->{$guid_id} = { _status => 'A' };
    }

    return $changes->{$guid_id};
}

*add_directory = *add_file;

sub open_file
{
    my ($self, $path) = @_;
    my $branch_path = $self->{branch_path};
    return undef unless length($path) > length($branch_path);

    assert($branch_path eq substr($path, 0, length($branch_path))) if DEBUG;
    $path = substr($path, length($branch_path) + 1);
    my $guid_id = $self->_file_guid_id($path);

    my $changes = $self->{changes};
    assert(!exists $changes->{$guid_id}) if DEBUG;

    return $changes->{$guid_id} = {};
}

*open_directory = *open_file;

sub change_file_prop
{
    my ($self, $baton, $name, $value) = @_;
    return unless defined $baton;

    # Don't bother storing the special 'entry' properties, since on their own
    # they don't represent changes that should affect what gets republished.
    return if $name =~ /^svn:entry:/;

    # Ignore properties with names which start with '_' because they might
    # interfere with the special values we keep in the same hash.  You can
    # still have them in your content, just not use them to decide what
    # publishing work to do.
    return if $name =~ /^_/;

    $baton->{_status} = 'M' unless exists $baton->{_status};
    $baton->{$name} = undef;
}

*change_dir_prop = *change_file_prop;

sub absent_file
{
    my ($self, $path) = @_;
    warn "file or directory '$path' cannot be updated for some reason";
}

*absent_directory = *absent_file;

sub close_file { }

*close_directory = *close_file;

sub apply_textdelta
{
    my ($self, $baton) = @_;
    return unless defined $baton;

    $baton->{_status} = 'M' unless exists $baton->{_status};
    assert($baton->{_status} ne 'D') if DEBUG;

    # The content may have changed, but we can't be sure without until
    # we later compare the content in the start and end revisions, after
    # the editor has finished.  This just indicates we should check.
    $baton->{_content_maybe} = undef;

    return;         # no need to actually apply the delta
}

sub abort_edit
{
    my ($self, $pool) = @_;
    # TODO
    print STDERR "abort_edit: self=$self, pool=$pool;\n";
}

# This is similar to Daizu::Revision::file_guid() except that:
#  * the revision we look in is always end_rev
#  * there's no need to do a join, because we only need the guid_id value
#  * the GUID is expected to exist
sub _file_guid_id
{
    my ($self, $path) = @_;
    my ($guid_id) = $self->{db}->selectrow_array(q{
        select guid_id
        from file_path
        where branch_id = ?
          and path = ?
          and first_revnum <= ?
          and (last_revnum is null or last_revnum >= ?)
    }, undef, $self->{branch_id}, $path, $self->{end_rev}, $self->{end_rev});
    assert(defined $guid_id) if DEBUG;
    return $guid_id;
}

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

1;
# vi:ts=4 sw=4 expandtab
