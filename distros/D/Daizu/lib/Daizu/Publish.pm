package Daizu::Publish;
use warnings;
use strict;

use base 'Exporter';
our @EXPORT_OK = qw(
    file_changes_between_revisions
    do_publishing_url_updates
    urls_which_need_publishing
    do_publication_work
    publish_urls
    publish_redirect_map publish_gone_map
    update_live_sites
);

use DateTime;
use Digest::SHA1 qw( sha1_base64 );
use File::Path qw( mkpath );
use Path::Class qw( file );
use Digest::SHA1;
use Carp qw( croak );
use Carp::Assert qw( assert DEBUG );
use Daizu::Wc;
use Daizu::Publish::Editor;
use Daizu::Util qw(
    trim like_escape validate_date
    db_row_id db_select db_insert db_update
    transactionally
    guid_first_last_times get_subversion_properties
    aggregate_map_changes
    instantiate_generator
);

=head1 NAME

Daizu::Publish - functions for publishing output

=head1 DESCRIPTION

This module contains various functions used for publishing content.
A lot of the code in here is for implementing the C<daizu publish>
command, which means working out what changes have been made to content
since the last time it was run.

=head1 FUNCTIONS

The following functions are available for export from this module.
None of them are exported by default.

=over

=item file_changes_between_revisions($cms, $start_rev, $end_rev)

Returns a reference to a hash describing what changes where made
between revision C<$start_rev> and revision C<$end_rev> in the content
repository.

The keys to the hash are the GUID IDs for the files changed (not
paths, because one of the the changes might have been the file getting
renamed).  Each of the values is another hash, in the same format
as for the C<$changes> value of the
L<url_updates_for_file_change() method|Daizu::Gen/$gen-E<gt>url_updates_for_file_change($wc_id, $guid_id, $file_id, $status, $changes)>.

This is all run in a transaction.

=cut

sub file_changes_between_revisions
{
    my ($cms, $start_rev, $end_rev) = @_;
    croak 'usage: file_changes_between_revisions($cms, $start_rev, $end_rev)'
        unless defined $start_rev && defined $end_rev;
    return transactionally($cms->{db}, \&_file_changes_between_revisions_txn,
                           $cms, $start_rev, $end_rev);
}

sub _file_changes_between_revisions_txn
{
    my ($cms, $start_rev, $end_rev) = @_;
    my $db = $cms->{db};

    my $live_wc = $cms->live_wc;
    my $latest_rev = $live_wc->current_revision;
    assert($latest_rev >= 1) if DEBUG;

    croak "end revision r$end_rev hasn't been loaded yet"
        if $end_rev > $latest_rev;

    croak "bad start_rev revision number r$start_rev"
        if $start_rev < 0;
    croak "bad revisions for publication job (r$start_rev to r$end_rev)"
        unless $end_rev > $start_rev;

    my %changes;    # keys are GUID ID
    my $editor = Daizu::Publish::Editor->new(
        cms => $cms,
        db => $db,
        start_rev => $start_rev,
        end_rev => $end_rev,
        branch_id => $live_wc->{branch_id},
        branch_path => $live_wc->{branch_path},
        changes => \%changes,
    );
    my $ra = $cms->{ra};
    my $reporter = $ra->do_update($end_rev, $live_wc->{branch_path}, 1,
                                  $editor);
    $reporter->set_path('', $start_rev, 0, undef);
    $reporter->finish_report;

    # Remove any entries for GUIDs which weren't changed (these will be
    # directories which were opened in the editor so that their descenants
    # could be modified).
    for (keys %changes) {
        delete $changes{$_} unless keys %{$changes{$_}};
    }

    while (my ($guid_id, $change) = each %changes) {
        my $status = $change->{_status};
        my ($old_path, $new_path);
        $change->{_old_path} = $old_path
                             = _file_path($db, $live_wc, $guid_id, $start_rev)
            unless $status eq 'A';
        $change->{_new_path} = $new_path
                             = _file_path($db, $live_wc, $guid_id, $end_rev)
            unless $status eq 'D';

        # Check whether actual file content has changed.
        # TODO - this isn't actually needed for the current generators, so
        # can I instead provide a function to do it only when necessary?
        if (exists $change->{_content_maybe}) {
            delete $change->{_content_maybe};
            if ($status eq 'M') {
                my $old_sha1 = _file_data_hash($ra, $old_path, $start_rev);
                my $new_sha1 = _file_data_hash($ra, $new_path, $end_rev);
                $change->{_content} = undef;
            }
        }

        my ($old_props, $new_props);
        $old_props = get_subversion_properties($ra, $old_path, $start_rev)
            unless $status eq 'A';
        $new_props = get_subversion_properties($ra, $new_path, $end_rev)
            unless $status eq 'D';

        $change->{_old_article} = _is_article($old_props);
        $change->{_new_article} = _is_article($new_props);

        $change->{_old_issued} = _issued_at($db, $guid_id, $old_props)
            if $status eq 'D' ||
               ($status eq 'M' && exists $change->{'dcterms:issued'});
        $change->{_new_issued} = _issued_at($db, $guid_id, $new_props)
            if $status eq 'A' ||
               ($status eq 'M' && exists $change->{'dcterms:issued'});

        my ($cur_path, $cur_props, $cur_rev);
        if ($status eq 'D') {
            $cur_path = $old_path;
            $cur_props = $old_props;
            $cur_rev = $start_rev;
        }
        else {
            $cur_path = $new_path;
            $cur_props = $new_props;
            $cur_rev = $end_rev;
        }

        if (exists $cur_props->{'daizu:generator'}) {
            $change->{_generator} = $cur_props->{'daizu:generator'};
        }
        else {
            my $path = $cur_path;
            while ($path =~ m!/!) {
                $path =~ s!/[^/]+\z!!;
                my $props = get_subversion_properties($ra, $path, $cur_rev);
                assert(defined $props) if DEBUG;
                next unless exists $props->{'daizu:generator'};
                $change->{_generator} = $props->{'daizu:generator'};
                last;
            }
            $change->{_generator} = 'Daizu::Gen'
                unless exists $change->{_generator};
        }

        # Provide the old values of the properties if available.
        if ($status ne 'A') {
            for (keys %$change) {
                next if /^_/;
                $change->{$_} = $old_props->{$_};
            }
        }
    }

    return \%changes;
}

# Return the full path, including branch path, of $guid_id in $revnum.
sub _file_path
{
    my ($db, $wc, $guid_id, $revnum) = @_;
    my ($path) = $db->selectrow_array(q{
        select path
        from file_path
        where branch_id = ?
          and guid_id = ?
          and first_revnum <= ?
          and (last_revnum is null or last_revnum >= ?)
    }, undef, $wc->{branch_id}, $guid_id, $revnum, $revnum);
    assert(defined $path) if DEBUG;
    return "$wc->{branch_path}/$path";
}

# Return a SHA1 hash of the content of the file at $path in revision $revnum.
sub _file_data_hash
{
    my ($ra, $path, $revnum) = @_;
    assert(defined $path) if DEBUG;

    my $stat = $ra->stat($path, $revnum);
    assert(defined $stat) if DEBUG;

    # If it's a directory, just pretend it was an empty file.
    return '2jmj7l5rSw0yVb/vlWAYkK/YBwk' if $stat->kind == $SVN::Node::dir;

    my $data = '';
    open my $fh, '>', \$data
        or die "error creating memory file: $!";
    binmode $fh or die $!;
    $ra->get_file($path, $revnum, $fh);

    return sha1_base64($data);
}

# Return '1' or '0' to indicate whether the file with properties $props
# is an article or not.
sub _is_article
{
    my ($props) = @_;
    return 0 unless defined $props;
    my $type = $props->{'daizu:type'};
    return defined $type && trim($type) eq 'article' ? 1 : 0;
}

# Return a DateTime value for the 'issued' timestamp of the file $guid_id
# with the properties $props.
sub _issued_at
{
    my ($db, $guid_id, $props) = @_;
    my $time = validate_date($props->{'dcterms:issued'});
    ($time, undef) = guid_first_last_times($db, $guid_id)
        unless defined $time;
    assert(defined $time) if DEBUG;
    return $time;
}

=item do_publishing_url_updates($cms, $changes)

Updates the URLs for any changed files described by C<$changes>,
which should be the value returned from the
L<file_changes_between_revisions() function|/file_changes_between_revisions($cms, $start_rev, $end_rev)>.

This starts by using the
L<url_updates_for_file_change() method|Daizu::Gen/$gen-E<gt>url_updates_for_file_change($wc_id, $guid_id, $file_id, $status, $changes)>
to figure out if any other files need their URLs updating.  Then, for
any such files and for all the ones given in C<$changes>, it calls the
L<update_urls_in_db() method|Daizu::File/$file-E<gt>update_urls_in_db([$dup_urls])>
to do the updates.

This returns a reference to a hash containing the following keys, each of
which is itself a reference to a hash:

=over

=item url_activated, url_deactivated, url_changed

Keys are actual URLs.  They are included if the URL update process
has caused them to become newly active (which means they need to be
published), or have been deactivated, or the URL itself has changed
but the new one still points to basically the same content.  The values
in all cases are URL info hashes.

=item update_redirect_maps, update_gone_maps

Keys are filenames of rewrite maps named in the Daizu configuration file.
Only ones which need to be updated to reflect the URL changes are included
in these hashes.  The values are the hashes of output configuration
information Daizu uses internally to reflect the C<output> XML element.

=back

All of this is done within a database transaction.

=cut

sub do_publishing_url_updates
{
    my ($cms, $changes) = @_;
    return transactionally($cms->{db}, \&_do_publishing_url_updates_txn,
                           $cms, $changes);
}

sub _do_publishing_url_updates_txn
{
    my ($cms, $changes) = @_;
    my $db = $cms->{db};
    my $wc_id = $cms->live_wc->id;

    # Collect list of GUIDs (as keys of this hash) for which URLs need to
    # be updated in addition to the files which were actually changed.
    my %other_guids_to_update;
    while (my ($guid_id, $change) = each %$changes) {
        my ($gen, $file_id) = _file_generator($cms, $wc_id, $guid_id, $change);
        my $update = $gen->url_updates_for_file_change(
                $wc_id, $guid_id, $file_id, $change->{_status}, $change);
        assert(defined $update && ref($update) eq 'ARRAY') if DEBUG;
        for (@$update) {
            next if exists $changes->{$_};
            next if exists $other_guids_to_update{$_};
            $other_guids_to_update{$_} = undef;
        }
    }

    # These are aggregate versions of the same variables as in the
    # update_urls_in_db() function in Daizu::File.  Look there for
    # details of what they mean.
    my (%redirects_changed, %gone_changed);
    my (%url_activated, %url_deactivated, %url_changed);

    # Update URLs for files which have changed.
    my %dup_urls;
    while (my ($guid_id, $change) = each %$changes) {
        if ($change->{_status} ne 'D') {
            # Added or modified, so regenerate URLs for the file and keep
            # track of any important changes to them.
            my $file = Daizu::File->new($cms, $change->{_file_id});
            my $url_changes = $file->update_urls_in_db(\%dup_urls);

            aggregate_map_changes($url_changes, \%redirects_changed,
                                  \%gone_changed);
            _aggregate_url_changes($url_changes, $guid_id, \%url_activated,
                                   \%url_deactivated, \%url_changed);
        }
        else {
            _deactivate_urls_for_deleted_file($db, $wc_id, $guid_id,
                                              \%dup_urls, \%url_deactivated);
        }
    }

    # Do URL updates for additional files.
    for my $guid_id (keys %other_guids_to_update) {
        my $file_id = db_row_id($db, 'wc_file',
            wc_id => $wc_id,
            guid_id => $guid_id,
        );

        if (defined $file_id) {
            my $file = Daizu::File->new($cms, $file_id);
            my $url_changes = $file->update_urls_in_db(\%dup_urls);

            aggregate_map_changes($url_changes, \%redirects_changed,
                                  \%gone_changed);
            _aggregate_url_changes($url_changes, $guid_id, \%url_activated,
                                   \%url_deactivated, \%url_changed);
        }
        else {
            _deactivate_urls_for_deleted_file($db, $wc_id, $guid_id,
                                              \%dup_urls, \%url_deactivated);
        }
    }

    # All duplicates should have been resolved by now.
    croak "new URL '$_' would conflict with existing URL"
        for keys %dup_urls;

    return {
        update_redirect_maps => \%redirects_changed,
        update_gone_maps => \%gone_changed,
        url_activated => \%url_activated,
        url_deactivated => \%url_deactivated,
        url_changed => \%url_changed,
    };
}

# Add URL changes to the aggregate versions, and at the same
# time record information about the file which they belong to.
sub _aggregate_url_changes
{
    my ($changes, $guid_id, $url_activated, $url_deactivated,
        $url_changed) = @_;

    while (my ($url, $info) = each %{$changes->{url_activated}}) {
        assert(!exists $url_activated->{$url}) if DEBUG;
        if (exists $url_deactivated->{$url}) {
            # The URL has been deactivated by one file and reactivated
            # by this one, which we don't count as being a change.
            delete $url_deactivated->{$url};
        }
        else {
            $info->{guid_id} = $guid_id;
            $url_activated->{$url} = $info;
        }
    }

    while (my ($url, $info) = each %{$changes->{url_deactivated}}) {
        assert(!exists $url_deactivated->{$url}) if DEBUG;
        assert(!exists $url_activated->{$url}) if DEBUG;
        $info->{guid_id} = $guid_id;
        $url_deactivated->{$url} = $info;
    }

    while (my ($url, $info) = each %{$changes->{url_changed}}) {
        assert(!exists $url_deactivated->{$url}) if DEBUG;
        assert(!exists $url_activated->{$url}) if DEBUG;
        assert(!exists $url_changed->{$url}) if DEBUG;
        $info->{guid_id} = $info->{old_url_info}{guid_id} = $guid_id;
        $url_changed->{$url} = $info;
    }
}

sub _deactivate_urls_for_deleted_file
{
    my ($db, $wc_id, $guid_id, $dup_urls, $url_deactivated) = @_;

    my $sth = $db->prepare(q{
        select *
        from url
        where wc_id = ?
          and guid_id = ?
          and status = 'A'
    });
    $sth->execute($wc_id, $guid_id);

    while (my ($url_info) = $sth->fetchrow_hashref) {
        my $url = $url_info->{url};
        if (exists $dup_urls->{$url}) {
            my $dup = $dup_urls->{$url};
            db_update($db, url => $dup->{id},
                guid_id => $dup->{guid_id},
                generator => $dup->{generator},
                method => $dup->{method},
                argument => $dup->{argument},
                content_type => $dup->{type},
            );
            delete $dup_urls->{$url};
        }
        else {
            db_update($db, url => $url_info->{id}, status => 'G');
            $url_deactivated->{$url} = { %$url_info };
        }
    }
}

=item urls_which_need_publishing($cms, $start_rev, $changes, $url_activated, $url_deactivated, $url_changed)

Figures out which URLs need to be published or deleted on the live websites to
reflect changes in the content repository.  C<$start_rev> should be the
revision just before the changes began (the end revision has to be the current
one of the live working copy).  C<$changes> is the value returned from the
L<file_changes_between_revisions() function|/file_changes_between_revisions($cms, $start_rev, $end_rev)>.

The last three arguments should be the corresponding values returned by the
L<do_publishing_url_updates() function|/do_publishing_url_updates($cms, $changes)>.

Returns a list of two values, each of which is a reference to a hash.
The first contains information about URLs which need to be published
to bring the live websites up to date, and the second URLs which have
to be deleted.  The keys are the actual URLs, and the values are URL info
hashes.

It is this function which calls the methods
L<publishing_for_file_change()|Daizu::Gen/$gen-E<gt>publishing_for_file_change($wc_id, $guid_id, $file_id, $status, $changes)>
and
L<publishing_for_url_change()|Daizu::Gen/$gen-E<gt>publishing_for_url_change($wc_id, $status, $old_url_info, $new_url_info)>
on generators, so it includes URLs which need to be pubilshed because
of their say-so.

=cut

sub urls_which_need_publishing
{
    my ($cms, $start_rev, $changes, $url_activated, $url_deactivated,
        $url_changed) = @_;
    my $db = $cms->{db};
    my $wc_id = $cms->live_wc->id;

    # Keys are URLs, values are URL info.  Each of these needs to be published
    # either because it's new or needs regenerating.  We start with the new
    # ones and then add any others the generators think need doing.
    my %publish_url = %$url_activated;

    # Same as above, but for URLs whose output files need to be deleted.
    my %delete_url = %$url_deactivated;

    # URLs generated by changed files need to be published, as do any which
    # the generator for it says need publishing.
    while (my ($guid_id, $change) = each %$changes) {
        # Add URLs for the file itself.
        my $sth = $db->prepare(q{
            select *
            from url
            where wc_id = ?
              and guid_id = ?
        });
        $sth->execute($wc_id, $guid_id);
        while (my $info = $sth->fetchrow_hashref) {
            next if exists $publish_url{$info->{url}};
            $publish_url{$info->{url}} = { %$info };
        }

        # Ask the generator for any other URLs it wants republished.
        my ($gen, $file_id) = _file_generator($cms, $wc_id, $guid_id, $change);
        my $publish = $gen->publishing_for_file_change(
                $wc_id, $guid_id, $file_id, $change->{_status}, $change);
        assert(defined $publish && ref($publish) eq 'ARRAY') if DEBUG;

        for (@$publish) {
            next if exists $publish_url{$_};
            my $info = $db->selectrow_hashref(q{
                select *
                from url
                where wc_id = ?
                  and url = ?
            }, undef, $wc_id, $_);
            assert(defined $info) if DEBUG;
            $publish_url{$_} = { %$info };
        }
    }

    # Publishing dependencies of newly activated URLs.
    while (my (undef, $info) = each %$url_activated) {
        _url_deps($cms, $wc_id, 'A', undef, $info, \%publish_url);
    }

    # For changed URLs.
    while (my (undef, $info) = each %$url_changed) {
        _url_deps($cms, $wc_id, 'M', $info->{old_url_info}, $info,
                  \%publish_url);

        # The new version of the changed URL needs to be published, and the
        # previous version deleted.
        my $url = $info->{url};
        $publish_url{$url} = $info unless exists $publish_url{$url};
        $delete_url{$url} = $info unless exists $delete_url{$url};
    }

    # For deactivated URLs.
    while (my (undef, $info) = each %$url_deactivated) {
        _url_deps($cms, $wc_id, 'D', $info, undef, \%publish_url);
    }

    return \%publish_url, \%delete_url;
}

sub _url_deps
{
    my ($cms, $wc_id, $status, $old_url_info, $new_url_info, $publish_url) = @_;

    my ($gen) = _url_generator($cms, $wc_id, undef,
                               ($new_url_info || $old_url_info));
    my $publish = $gen->publishing_for_url_change(
            $wc_id, $status, $old_url_info, $new_url_info);
    assert(defined $publish && ref($publish) eq 'ARRAY') if DEBUG;

    for my $url (@$publish) {
        next if exists $publish_url->{$url};
        my $info = $cms->{db}->selectrow_hashref(q{
            select *
            from url
            where url = ?
        }, undef, $url);
        assert(defined $info) if DEBUG;
        $publish_url->{$url} = { %$info };
    }
}

=item do_publication_work($cms, $publish_url, $delete_url, $update_redirect_maps, $update_gone_maps)

This actually does the publication work required to bring live sites
up to date with changes made in the content repository, given enough
information about what to do.  It doesn't return anything.

C<$publish_url> and C<$delete_url> should be the two values returned from the
L<urls_which_need_publishing() function|/urls_which_need_publishing($cms, $start_rev, $changes, $url_activated, $url_deactivated, $url_changed)>.
C<$update_redirect_maps> and C<$update_gone_maps> should be the corresponding
values returned by the
L<do_publishing_url_updates() function|/do_publishing_url_updates($cms, $changes)>.

This first does publication for all the specified URLs, writing them in to
the appropriate files in the appropriate document roots.  See the
L<publish_urls() function|/publish_urls($cms, $file, $generator, $method, $urls)>
for full details of how the output is written.

After that, the redirect and 'gone' maps are published.  Finally the files
associated with any deleted URLs are removed.

TODO - should this do rsyncing afterwards?

=cut

sub do_publication_work
{
    my ($cms, $publish_url, $delete_url, $update_redirect_maps,
        $update_gone_maps) = @_;
    my $wc_id = $cms->live_wc->id;

    # Publish new URLs.
    while (my ($url, $info) = each %$publish_url) {
        my ($gen, $file_id) = _url_generator($cms, $wc_id, undef, $info);
        my $file = Daizu::File->new($cms, $file_id);
        # TODO - maybe call this just once for each guid/method pair?
        publish_urls($cms, $file, $gen, $info->{method}, [ $info ]);
    }

    # Output rewrite maps.
    while (my (undef, $config) = each %$update_redirect_maps) {
        publish_redirect_map($cms, $wc_id, $config);
    }
    while (my (undef, $config) = each %$update_gone_maps) {
        publish_gone_map($cms, $wc_id, $config);
    }

    # Delete deactivated URLs.
    while (my ($url, $info) = each %$delete_url) {
        assert(!exists $publish_url->{$url}) if DEBUG;
        my $full_filename = _url_output_filename($cms, $url);
        next unless -f $full_filename;
        unlink $full_filename
            or warn "Error deleting deactivated URL '$url'.\n";
    }

    # Run rsync.
    # TODO
}

sub _file_generator
{
    my ($cms, $wc_id, $guid_id, $change) = @_;
    my $file_id;
    my $root_file;

    if ($change->{_status} ne 'D') {
        my $root_file_id;
        if (exists $change->{_file_id}) {
            $file_id = $change->{_file_id};
            $root_file_id = $change->{_root_file_id};
        }
        else {
            ($file_id, $root_file_id) = db_select($cms->{db}, 'wc_file',
                { wc_id => $wc_id, guid_id => $guid_id },
                qw( id root_file_id ),
            );
            assert(defined $file_id) if DEBUG;
            $root_file_id = $file_id unless defined $root_file_id;
            $change->{_file_id} = $file_id;
            $change->{_root_file_id} = $root_file_id;
        }
        $root_file = Daizu::File->new($cms, $root_file_id);
    }
    else {  # deleted, so fake up the root file
        $root_file = { path => $change->{_old_path} };
    }

    my $gen = instantiate_generator($cms, $change->{_generator}, $root_file);
    return ($gen, $file_id);
}

# If $start_rev is defined then that means that the URLs are now deactivated,
# and it must therefore be used to find a path to fake the root file with.
# Otherwise the URL is still active, so we should be able to find the file
# in the working copy.
sub _url_generator
{
    my ($cms, $wc_id, $start_rev, $url_info) = @_;
    my $file_id;
    my $root_file;

    if (defined $start_rev) {   # a deactivated URL, so fake up root file
        $root_file = {
            path => _file_path($cms->{db}, $wc_id, $url_info->{guid_id},
                               $start_rev),
        };
    }
    else {
        my $root_file_id;
        if (exists $url_info->{file_id}) {
            $file_id = $url_info->{file_id};
            $root_file_id = $url_info->{root_file_id};
        }
        else {
            ($file_id, $root_file_id) = db_select($cms->{db}, 'wc_file',
                { wc_id => $wc_id, guid_id => $url_info->{guid_id} },
                qw( id root_file_id ),
            );
            assert(defined $file_id) if DEBUG;
            $root_file_id = $file_id unless defined $root_file_id;
            $url_info->{file_id} = $file_id;
            $url_info->{root_file_id} = $root_file_id;
        }
        $root_file = Daizu::File->new($cms, $root_file_id);
    }

    my $gen = instantiate_generator($cms, $url_info->{generator}, $root_file);
    return ($gen, $file_id);
}

=item publish_urls($cms, $file, $generator, $method, $urls)

Publishes the output for the URLs whose info hashes are supplied
(in an array reference) in C<$urls>.  If there is more than one
URL they are all published using the same generator with a single
method call.

C<$file> should be a L<Daizu::File> object suitable for passing to
the generator method with the name C<$method> on class C<$generator>.

This writes the new content into temporary files alongside the intended output
file first and then moves them into place (possibly over the top of an older
version of the file) when complete, so if publication fails part way through it
won't leave output half written.  It should clear away the temporary files if
something goes wrong.  Note that it doesn't overwrite an older file if it is
identical to the new one, so that the modification time of the file will be
unaffected if the publication wasn't really necessary.

=cut

sub publish_urls
{
    my ($cms, $file, $generator, $method, $urls) = @_;

    eval { _publish_urls_work($cms, $file, $generator, $method, $urls) };

    if ($@) {
        # Clean up any temp files left behind.
        for my $url_info (@$urls) {
            my $filename = $url_info->{_tmp_filename};
            next unless defined $filename;
            warn "Cleaning up unfinished temp file '$filename'.\n";
            unlink $filename
                or warn "Error deleting temp file '$filename': $!\n";
            delete $url_info->{_tmp_filename};
        }

        die $@;
    }
}

# This is called in an eval{} so that any half-published temp files can
# be cleaned up if it breaks.
sub _publish_urls_work
{
    my ($cms, $file, $generator, $method, $urls) = @_;

    for my $url_info (@$urls) {
        my $out_url = $url_info->{url} = URI->new($url_info->{url});

        my $full_filename = _url_output_filename($cms, $out_url, 1);
        my $tmp_filename = "$full_filename.daizutmp";
        open my $fh, '>', $tmp_filename
            or die "Error opening output file '$tmp_filename': $!\n";
        binmode $fh
            or die "Error setting binmode on output file '$tmp_filename': $!\n";
        assert(!defined $url_info->{fh}) if DEBUG;
        $url_info->{fh} = $fh;
        $url_info->{_full_filename} = $full_filename;
        $url_info->{_tmp_filename} = $tmp_filename;
    }

    $generator->$method($file, $urls);

    # Close the output files explicitly, so that any errors encountered while
    # flushing buffers are correctly reported.  Also make them executable
    # if the original file in Subversion is (for CGI scripts).
    for my $url_info (@$urls) {
        my $filename = $url_info->{_full_filename};
        my $tmpfile = $url_info->{_tmp_filename};

        if (defined $url_info->{fh}) {
            close $url_info->{fh}
                or die "Error closing output file '$tmpfile': $!\n";
        }
        delete $url_info->{fh};

        if ($file->property('svn:executable')) {
            my $umask = umask;
            if (defined $umask) {
                chmod +(0777 & ~$umask), $tmpfile
                    or die "Error making '$tmpfile' executable: $!\n";
            }
        }

        if (!-f $filename || _file_hash($tmpfile) ne _file_hash($filename) ||
            -x $tmpfile ne -x $filename)
        {
            # Move the temp file into place, possibly overrwritting an older
            # published version.
            rename $tmpfile, $filename
                or die "Error moving file '$tmpfile' into place: $!\n";
        }
        else {
            # The new version of the file is identical to an older one which
            # is still present in the document root, so we might as well just
            # delete the temp file.  This wil mean that the timestamp of the
            # live version won't get fiddled with when no real changes have
            # been made, and it will save rsync from having to do a comparison.
            unlink $tmpfile
                or die "Error deleting temp file '$tmpfile': $!\n";
        }
    }
}

sub _url_output_filename
{
    my ($cms, $url, $create_dir) = @_;

    my ($config, $docroot, $path, $filename) = $cms->output_config($url);
    die "No output path defined for URL '$url'\n"
        unless defined $docroot;

    mkpath(file($docroot, $path)->stringify)
        if $create_dir;

    return file($docroot, $path, $filename);
}

# Return a SHA1 digest of a file's content (a file on the filesystem, not one
# in a database working copy).
sub _file_hash
{
    my ($filename) = @_;

    open my $fh, '<', $filename
        or die "Error opening file '$filename' for digesting: $!\n";
    binmode $fh
        or die "Error binmoding file '$filename' for digesting: $!\n";
    my $digest = Digest::SHA1->new;
    $digest->addfile($fh);

    return $digest->digest;
}

=item publish_redirect_map($cms, $wc_id, $config)

TODO

TODO - redirect and gone maps should be published in the same way as
URL content, with the file first written to a different filename, then
compared with the old version, then moved into place if necessary.

=cut

sub publish_redirect_map
{
    my ($cms, $wc_id, $config) = @_;

    my $filename = $config->{redirect_map};
    assert(defined $filename) if DEBUG;
    open my $fh, '>', $filename
        or die "Error opening redirect map '$filename': $!\n";

    my $url = $config->{url};
    my $sth = $cms->db->prepare(q{
        select u.url, r.url
        from url u
        inner join url r on r.id = u.redirect_to_id
        where u.status = 'R'
          and u.wc_id = ?
          -- URL is exact match or is more precise
          and (u.url = ? or (? like '%/' and u.url like ?))
        order by u.url
    });
    $sth->execute($wc_id, $url, $url, like_escape($url) . '%');

    while (my ($src, $target) = $sth->fetchrow_array) {
        my $path = _map_path($src, $config);
        print $fh "$path\t$target\n"
            if defined $path;
    }

    close $fh or die "Error closing redirect map file '$filename': $!\n";
}

=item publish_gone_map($cms, $wc_id, $config)

TODO

=cut

sub publish_gone_map
{
    my ($cms, $wc_id, $config) = @_;

    my $filename = $config->{gone_map};
    assert(defined $filename) if DEBUG;
    open my $fh, '>', $filename
        or die "Error opening gone map '$filename': $!\n";

    my $url = $config->{url};
    my $sth = $cms->db->prepare(q{
        select url
        from url
        where status = 'G'
          and wc_id = ?
          -- URL is exact match or is more precise
          and (url = ? or (? like '%/' and url like ?))
        order by url
    });
    $sth->execute($wc_id, $url, $url, like_escape($url) . '%');

    while (my ($url) = $sth->fetchrow_array) {
        my $path = _map_path($url, $config);
        print $fh "$path\t1\n"
            if defined $path;
    }

    close $fh or die "Error closing gone map file '$filename': $!\n";
}

sub _map_path
{
    my ($url, $config) = @_;

    $url = URI->new($url);
    my $path = $url->rel($config->{url});
    $path = '/' if $path eq './';
    return if $path eq $url || $path =~ m!^\.\.?/!;

    assert(defined $path && $path ne '') if DEBUG;
    $path = "/$path" unless $path =~ m!^/!;

    return $path;
}

=item update_live_sites($cms, $start_rev)

TODO

=cut

sub update_live_sites
{
    my ($cms, $start_rev) = @_;
    return transactionally($cms->{db}, \&_update_live_sites_txn,
                           $cms, $start_rev);
}

sub _update_live_sites_txn
{
    my ($cms, $start_rev) = @_;
    my $end_rev = $cms->live_wc->current_revision;

    my ($cur_rev) = db_select($cms->{db}, live_revision => {}, 'revnum');
    $start_rev = $cur_rev unless defined $start_rev;

    if (!defined $start_rev) {
        db_insert($cms->{db}, 'live_revision', revnum => $end_rev);
        die "No live sites tracked yet.  I've initialized the database\n" .
            "to use the latest revision as a starting point, but you\n" .
            "need to publish all the content to start with before it\n" .
            "makes sense to use this feature.\n";
    }

    return if $start_rev == $end_rev;   # nothing to do

    # These calls do all the actual work.
    my $changes = file_changes_between_revisions($cms, $start_rev, $end_rev);
    my $work = do_publishing_url_updates($cms, $changes);
    my ($publish_url, $delete_url) = urls_which_need_publishing(
        $cms, $start_rev, $changes, $work->{url_activated},
        $work->{url_deactivated}, $work->{url_changed});
    do_publication_work(
        $cms, $publish_url, $delete_url,
        $work->{update_redirect_maps}, $work->{update_gone_maps});

    # Keep track of the new revision we've published up to.
    if (defined $cur_rev) {
        db_update($cms->{db}, 'live_revision', { revnum => $cur_rev },
                  revnum => $end_rev);
    }
    else {
        db_insert($cms->{db}, 'live_revision', revnum => $end_rev);
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
