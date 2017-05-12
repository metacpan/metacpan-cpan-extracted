package Daizu::Revision;
use warnings;
use strict;

use base 'Exporter';
our @EXPORT_OK = qw(
    load_revision
    known_branches branch_and_path file_guid
);

use SVN::Core;
use SVN::Ra;
use SVN::Repos;
use SVN::Delta;
use Carp qw( croak );
use Carp::Assert qw( assert DEBUG );
use Daizu::Util qw(
    like_escape
    validate_uri db_datetime
    db_row_exists db_select db_insert db_update transactionally
    mint_guid get_subversion_properties
);

=head1 NAME

Daizu::Revision - functions for loading revisions from Subversion

=head1 DESCRIPTION

These functions are used to load metadata about revisions (and the file
path changes made in them) from the Subversion into the PostgreSQL database.

=head1 FUNCTIONS

The following functions are available for export from this module.
None of them are exported by default.

=over

=item load_revision($cms, $desired_revnum)

Load information about new revisions, up to C<$desired_revnum>.
It starts from the revision after the last one which was loaded, and
is idempotent (so if you try to load the same revision twice there will
be no change).

If C<$desired_revnum> is not defined, loads up to the most recent revision
in the repository.

This can also be called as a method on a L<Daizu> object.

=cut

sub load_revision
{
    my ($cms, $desired_rev) = @_;
    croak "bad revision number r$desired_rev"
        if defined $desired_rev && $desired_rev < 1;

    return transactionally($cms->{db}, \&_load_revision_txn,
                           $cms, $desired_rev);
}

sub _load_revision_txn
{
    my ($cms, $desired_rev) = @_;
    my $db = $cms->{db};
    my $ra = $cms->{ra};

    my $latest_rev = $ra->get_latest_revnum;
    $desired_rev = $latest_rev
        unless defined $desired_rev;
    croak "can't load up to r$desired_rev, latest revision is r$latest_rev"
        if $desired_rev > $latest_rev;

    my $last_known_rev = db_select($db, revision => {}, 'max(revnum)');
    $last_known_rev ||= 0;
    assert($last_known_rev <= $latest_rev) if DEBUG;

    # Return quickly if there's nothing to do.
    return $last_known_rev
        if $last_known_rev >= $desired_rev;

    my $branches = known_branches($db);
    my $trunk_id = $branches->{trunk};

    for my $revnum (($last_known_rev + 1) .. $desired_rev) {
        my @modified;
        my (@added, @copied, @deleted);
        my $date;

        # Gather information about the changes in this revision.
        # The database is only updated later, after the callback is finished,
        # because we might need to get other information from $ra, and that's
        # not allowed while get_log() is running.
        $ra->get_log('/', $revnum, $revnum, 0, 1, 1, sub {
            my ($paths, undef, undef, $rev_date) = @_;
            $date = $rev_date;

            while (my ($full_path, $changes) = each %$paths) {
                my $action = $changes->action;

                # Modified files don't affect identity, we just need to record
                # their paths so that we can check for property changes that
                # might affect the GUID URI.  Only changes on trunk affect it.
                if ($action eq 'M') {
                    next unless $full_path =~ s!^/trunk/!! && $full_path ne '';
                    push @modified, $full_path;
                    next;
                }

                my ($branch_id, $path) = branch_and_path($branches, $full_path);

                # Ignore files which live outside branches, except when we
                # see a new branch being created, in which case make a note
                # of where it is in the 'branch' table.  We recognize a new
                # branch as a copy from an existing branch to a new location
                # outside any existing branches.
                if (!defined $branch_id) {
                    my $from = $changes->copyfrom_path;
                    next unless defined $from;
                    my $to = $full_path;
                    $_ =~ s!^/!! for $from, $to;
                    next unless exists $branches->{$from};
                    $path = '';
                    $branch_id = db_insert($db, 'branch', path => $to);
                    $branches->{$to} = $branch_id;
                }

                if ($action ne 'D') {       # add or replace
                    my $from_full_path = $changes->copyfrom_path;
                    if (defined $from_full_path) {
                        croak "Error in revision $revnum: file $full_path copied from root directory"
                            if $from_full_path eq '/';
                        my ($from_branch_id, $from_path) =
                            branch_and_path($branches, $from_full_path);
                        croak "Error in revision $revnum: file $full_path copied from unknown branch"
                            unless defined $from_branch_id;

                        push @copied, {
                            full_path => $full_path,
                            path => $path,
                            branch_id => $branch_id,
                            from_full_path => $from_full_path,
                            from_path => $from_path,
                            from_branch_id => $from_branch_id,
                            from_rev => $changes->copyfrom_rev,
                        };
                    }
                    else {
                        push @added, [ $branch_id, $path, $full_path ];
                    }
                }

                if ($action ne 'A') {       # delete or replace
                    push @deleted, [ $branch_id, $path ];
                }
            }
        });

        _add_revision($db, $revnum, $date);
        _revision_guid_modifications($ra, $db, $trunk_id, $revnum, \@modified)
            if @modified;
        _revision_guid_path_changes($cms, $ra, $db, $trunk_id, $revnum,
                                    \@added, \@copied, \@deleted)
            if @added || @copied || @deleted;
    }

    return $desired_rev;
}

=item known_branches($db)

Return a reference to a hash of known branches.  The keys are the paths,
and the values are the ID numbers found in the C<branch> table.

Dies if it can't find a branch with the path C<trunk>, because that indicates
a broken database.

=cut

sub known_branches
{
    my ($db) = @_;

    my $sth = $db->prepare('select id, path from branch');
    $sth->execute;

    my %branch;
    while (my ($id, $path) = $sth->fetchrow_array) {
        $branch{$path} = $id;
    }

    croak "there is no branch called 'trunk' in the database"
        unless exists $branch{trunk};

    return \%branch;
}

=item branch_and_path($branches, $path)

Return a list of two values, the ID number and path of the branch
which a file at C<$path> would be in, whether or not it actually exists.
The path should be relative to the root of the repository, for example
C<trunk/foo.html>.  It doesn't mater whether C<$path> starts with a forward
slash.

Returns nothing if the path is not in any branch, in which case Daizu CMS
will simply ignore it.

=cut

sub branch_and_path
{
    my ($branches, $path) = @_;
    $path =~ s/^\///;
    return if $path eq '/';     # Don't care about root directory

    # Figure out which branch this path is on.  Do this by checking
    # ever longer prefixes of the path, since that will allow us to
    # find 'trunk' very quickly.
    my @path = split '/', $path;
    my $branch_path = '';
    my $branch_id;
    while (@path) {
        $branch_path .= '/' unless $branch_path eq '';
        $branch_path .= shift @path;
        next unless exists $branches->{$branch_path};
        $branch_id = $branches->{$branch_path};
        last;
    }

    # Ignore changes to files which aren't in a branch we know about.
    return unless defined $branch_id;

    # The file/directory path relative to the branch directory.
    # Empty string for the top level directory.
    $path = $path eq $branch_path ? ''
                                  : substr $path, length($branch_path) + 1;

    return ($branch_id, $path);
}

=item file_guid($db, $branch_id, $path, $revnum)

Returns a reference to a hash of information about the GUID for the file
in branch C<$branch_id> at C<$path> in revision C<$revnum>, or C<undef>
if there is/was no such file.

The hash will contain the following keys:

=over

=item id

GUID ID.

=item is_dir

True iff the associated file is a directory.

=item uri

The GUID URI (usually starting with C<tag:>).  This will be the custom
GUID URI if overridden by a C<daizu:guid> property.

=item custom_uri

True if a C<daizu:guid> property has overridden the automatically
generated GUID URI.

=item first_revnum

The number of the first revision in which C<$path> was used for this
file in this branch.

=item last_revnum

The number of the last revision in which C<$path> was used for this
file in this branch, or C<undef> if it is still being used in the most
recently loaded revision.

=back

=cut

sub file_guid
{
    my ($db, $branch_id, $path, $revnum) = @_;

    return $db->selectrow_hashref(q{
        select g.id, g.is_dir, g.uri, g.old_uri, g.custom_uri,
               p.first_revnum, p.last_revnum
        from file_guid g
        inner join file_path p on g.id = p.guid_id
        where p.branch_id = ?
          and p.path = ?
          and p.first_revnum <= ?
          and (p.last_revnum is null or p.last_revnum >= ?)
    }, undef, $branch_id, $path, $revnum, $revnum);
}

sub _add_revision
{
    my ($db, $revnum, $date) = @_;
    assert(defined $revnum) if DEBUG;

    $date = db_datetime($date);
    croak "revision r$revnum has no datetime stamp, or it is invalid"
        unless defined $date;

    db_insert($db, 'revision',
        revnum => $revnum,
        committed_at => $date,
    );
}

sub _adjust_custom_uri
{
    my ($ra, $db, $path, $revnum, $guid) = @_;
    assert($path ne '') if DEBUG;

    my $full_path = "trunk/$path";
    my $props = get_subversion_properties($ra, $full_path, $revnum);
    return unless defined $props;   # not present in trunk

    if (exists $props->{'daizu:guid'}) {
        my $new_uri = validate_uri($props->{'daizu:guid'});
        croak "error in revision $revnum: invalid URI in 'daizu:guid' property on '$full_path'"
            unless defined $new_uri;
        $new_uri = $new_uri->canonical;

        if ($guid->{custom_uri}) {
            if ($guid->{uri} ne $new_uri) {
                # There was a custom URI already, but it has been changed.
                db_update($db, file_guid => $guid->{id}, uri => $new_uri);
            }
        }
        else {
            # The guid property has been added, so switch from the standard
            # guid to the custom one.
            $db->do(q{
                update file_guid
                set custom_uri = true,
                    old_uri = uri,
                    uri = ?
                where id = ?
            }, undef, $new_uri, $guid->{id});
        }
    }
    elsif ($guid->{custom_uri}) {
        # The guid property has been removed, so switch back to the
        # original standard GUID.
        $db->do(q{
            update file_guid
            set uri = old_uri,
                old_uri = null,
                custom_uri = false
            where id = ?
        }, undef, $guid->{id});
    }
}

sub _revision_guid_modifications
{
    my ($ra, $db, $trunk_id, $revnum, $modified) = @_;

    for my $path (@$modified) {
        assert($path ne '') if DEBUG;
        my $guid = file_guid($db, $trunk_id, $path, $revnum);
        croak "modified file 'trunk/$path' has no GUID in revision $revnum"
            unless defined $guid;
        db_update($db, file_guid => $guid->{id},
                  last_changed_revnum => $revnum);
        _adjust_custom_uri($ra, $db, $path, $revnum, $guid);
    }
}

sub _revision_guid_path_changes
{
    my ($cms, $ra, $db, $trunk_id, $revnum, $added, $copied, $deleted) = @_;

    # Record last revnum of deleted paths.
    for my $del (@$deleted) {
        my ($branch_id, $path) = @$del;

        if ($path eq '') {
            # If the top-level directory is deleted, that means delete
            # everything on the branch.
            db_update($db, file_path => { branch_id => $branch_id,
                                          last_revnum => undef },
                last_revnum => $revnum - 1,
            );
        }
        else {
            db_update($db, file_path => { branch_id => $branch_id,
                                          path => $path,
                                          last_revnum => undef },
                last_revnum => $revnum - 1,
            );

            # If it's a directory, mark the demise of all its children.
            $db->do(q{
                update file_path
                set last_revnum = ?
                where branch_id = ?
                  and path like ?
                  and last_revnum is null
            }, undef, $revnum - 1, $branch_id, like_escape($path) . '/%');
        }
    }

    # Process copies sorted in reverse order, so that subdirectories are
    # done before their parents.  That way, when I process all the paths
    # within a copied directory I can skip any which have already been
    # processed separately, because for example the target subdirectory was
    # copied from somewhere else.
    my %source_guid;
    my %added_path;
    for (sort { $b->{path} cmp $a->{path} } @$copied) {
        # If it's not the top-level directory, process the copy.
        my $is_dir = 1;
        if ($_->{from_path} ne '') {
            my $guid = file_guid($db, $_->{from_branch_id}, $_->{from_path},
                                 $_->{from_rev});
            croak "Error in revision $revnum: file $_->{full_path} copied from source with no GUID ($_->{from_full_path} r$_->{from_rev})"
                unless defined $guid;

            push @{$source_guid{$_->{branch_id}}{$guid->{id}}}, $_;
            undef $added_path{$_->{path}};
            $is_dir = $guid->{is_dir};
        }

        # If the path being copied is a directory, then also copy all of its
        # children from the same source.
        if ($is_dir) {
            my $branch_path =
                db_select($db, branch => $_->{branch_id}, 'path');
            my $from_branch_path =
                db_select($db, branch => $_->{from_branch_id}, 'path');

            my $sth = $db->prepare(q{
                select path, guid_id
                from file_path
                where branch_id = ?
                  and path like ?
                  and first_revnum <= ?
                  and (last_revnum is null or last_revnum >= ?)
            });
            $sth->execute($_->{from_branch_id},
                          ($_->{from_path} eq ''
                              ? '%'
                              : like_escape($_->{from_path}) . '/%'),
                          $_->{from_rev}, $_->{from_rev});

            my $prefix_len = length $_->{from_path};
            ++$prefix_len if $prefix_len;   # separating /

            while (my ($from_path, $guid_id) = $sth->fetchrow_array) {
                my $from_full_path = "$from_branch_path/$from_path";
                my $child_path = substr $from_path, $prefix_len;
                my $path = $_->{path} eq '' ? $child_path
                                            : "$_->{path}/$child_path";
                next if exists $added_path{$path};
                my $full_path = "$branch_path/$path";
                push @{$source_guid{$_->{branch_id}}{$guid_id}}, {
                    full_path => $full_path,
                    path => $path,
                    branch_id => $_->{branch_id},
                    from_full_path => $from_full_path,
                    from_path => $from_path,
                    from_branch_id => $_->{from_branch_id},
                    from_rev => $_->{from_rev},
                };
                undef $added_path{$path};
            }
        }
    }

    while (my ($branch_id, $guids) = each %source_guid) {
        while (my ($guid_id, $copies) = each %$guids) {
            my @copies = sort { $a->{full_path} cmp $b->{full_path} } @$copies;

            my $guid_already_present = db_row_exists($db, file_path =>
                guid_id => $guid_id,
                branch_id => $branch_id,
                last_revnum => undef,
            );

            # If there isn't already a live path in the target branch for this
            # GUID then one of the copies with it gets to keep it.
            if (!$guid_already_present) {
                my $keep = shift @copies;
                db_insert($db, 'file_path',
                    guid_id => $guid_id,
                    path => $keep->{path},
                    branch_id => $keep->{branch_id},
                    first_revnum => $revnum,
                );

                if ($keep->{branch_id} == $trunk_id) {
                    my $guid = file_guid($db, $trunk_id, $keep->{path},
                                         $revnum);
                    _adjust_custom_uri($ra, $db, $keep->{path}, $revnum, $guid);
                    db_update($db, file_guid => $guid->{id},
                              last_changed_revnum => $revnum);
                }
            }

            # Copies which can't keep their GUID, because it's already live
            # in the target branch, get treated just like adds without history.
            for (@copies) {
                push @$added, [ $_->{branch_id}, $_->{path}, $_->{full_path} ];
            }
        }
    }

    for my $add (@$added) {
        my ($branch_id, $path, $full_path) = @$add;
        next if $path eq '';

        # First mint a new GUID for it.
        my $is_dir = $ra->check_path($full_path, $revnum) == $SVN::Node::dir;
        my ($guid_id, $guid_uri) = mint_guid($cms, $is_dir, $path, $revnum);

        _adjust_custom_uri($ra, $db, $path, $revnum, {
            uri => $guid_uri,
            id => $guid_id,
            is_dir => $is_dir,
        });

        db_insert($db, file_path =>
            guid_id => $guid_id,
            path => $path,
            branch_id => $branch_id,
            first_revnum => $revnum,
        );
    }
}

=back

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

1;
# vi:ts=4 sw=4 expandtab
