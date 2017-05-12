package Daizu::Wc::UpdateEditor;
use warnings;
use strict;

use SVN::Delta;
use base 'SVN::Delta::Editor';

use Digest::SHA1 qw( sha1_base64 );
use Image::Size qw( imgsize );
use Carp qw( croak );
use Carp::Assert qw( assert DEBUG );
use Daizu::Revision qw( file_guid );
use Daizu::File;
use Daizu::Util qw(
    trim trim_with_empty_null validate_date db_datetime
    db_row_exists db_select db_insert db_update db_replace db_delete
    wc_file_data wc_set_file_data
    guid_first_last_times
);

=head1 NAME

Daizu::Wc::UpdateEditor - Subversion editor for updating database working copies

=head1 DESCRIPTION

This Subversion delta editor can be used to receive updates from Subversion
and load the new information into Daizu CMS database working copies.  For
example, to check out data into a fresh, newly created working copy:

=for syntax-highlight perl

    my $editor = Daizu::Wc::UpdateEditor->new(
        cms => $cms,
        db => $db,
        wc_id => $wc_id,
        revnum => $revnum,
        branch_id => $branch_id,
        branch_path => $branch_path,
    );

    my $reporter = $cms->ra->do_update($revnum, $branch_path, 1, $editor);
    $reporter->set_path('', 0, 1, undef);
    $reporter->finish_report;

This should be used inside a database transaction, so that the changes
can be rolled back if anything goes wrong.

The methods called by Subversion are described in the documentation for
L<SVN::Delta::Editor>.

Directory and file batons are a reference to a hash containing the
following values:

=over

=item id

ID number of their entry in the C<wc_file> table.

=item path

Relative to branch root (same as 'path' value in C<wc_file> table).

=item mime_type

If the property 'svn:mime-type' has been set on this file, then this
will be the value of it, otherwise C<undef>.

=item data

If this is a file and C<apply_textdelta()> has been called on it, there
is also a string which will hold the data of the file.  It is put in the
database when C<close_file()> is called.  Otherwise this will be C<undef>.

=item props

A reference to a hash of all properties set or deleted while the baton
was open.  It will be undef if no properties have been changed.  Used
during C<close_file()> and C<close_directory()> to call custom property
loaders if appropriate.

=item changed

True if the content or any properties of a file have been updated.
This is used when the file or directory is closed to determine whether
the 'modified_at' timestamp should be set.

=item added

True if the file or directory was added anew rather than opened.

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

    if (length($path) <= length($branch_path)) {
        # If this is the branch directory or something above it, then
        # all the files in the working copy should be deleted.
        assert($path eq substr($branch_path, 0, length($path))) if DEBUG;
        db_delete($db, 'wc_file', wc_id => $self->{wc_id});
    }
    else {
        # Delete a file or directory.  If it has children, then the database
        # will automatically delete those as well.
        assert($branch_path eq substr($path, 0, length($branch_path))) if DEBUG;
        $path = substr($path, length($branch_path) + 1);
        db_delete($db, 'wc_file',
            wc_id => $self->{wc_id},
            path => $path,
        );
    }
}

sub add_directory
{
    my ($self, $path, $baton) = @_;
    my $db = $self->{db};
    my $branch_path = $self->{branch_path};

    if (length($path) <= length($branch_path)) {
        # If this is the branch directory or something above it, just do a
        # sanity check.  We don't need to track this.
        assert($path eq substr($branch_path, 0, length($path))) if DEBUG;
        assert(!defined $baton) if DEBUG;
        return undef;
    }
    else {
        assert($branch_path eq substr($path, 0, length($branch_path))) if DEBUG;
        $path = substr($path, length($branch_path) + 1);
        my $guid = file_guid($db, $self->{branch_id}, $path, $self->{revnum});
        my $name = ($path =~ m!/([^/]+)\z!) ? $1 : $path;
        my ($issued, $modified) = guid_first_last_times($db, $guid->{id});

        my $parent_id = defined $baton ? $baton->{id} : undef;
        my ($generator, $root_file_id);
        if (defined $parent_id) {
            ($generator, $root_file_id) = db_select($db, wc_file => $parent_id,
                                                   'generator', 'root_file_id');
            $root_file_id = $parent_id
                unless defined $root_file_id;
        }
        else {
            $generator = 'Daizu::Gen';
        }

        my $file_id = db_insert($db, 'wc_file',
            wc_id => $self->{wc_id},
            guid_id => $guid->{id},
            parent_id => $parent_id,
            name => $name,
            path => $path,
            is_dir => 1,
            issued_at => db_datetime($issued),
            modified_at => db_datetime($modified),
            cur_revnum => $self->{revnum},
            data_len => 0,
            generator => $generator,
            root_file_id => $root_file_id,
        );
        return { id => $file_id, path => $path, added => 1 };
    }
}

sub open_directory
{
    my ($self, $path) = @_;
    my $branch_path = $self->{branch_path};

    if (length($path) <= length($branch_path)) {
        # If this is the branch directory or something above it, just do a
        # sanity check.  We don't need to track this.
        assert($path eq substr($branch_path, 0, length($path))) if DEBUG;
        return undef;
    }
    else {
        assert($branch_path eq substr($path, 0, length($branch_path))) if DEBUG;
        $path = substr($path, length($branch_path) + 1);
        my ($file_id, $content_type) = db_select($self->{db}, 'wc_file',
            { wc_id => $self->{wc_id}, path => $path },
            'id', 'content_type',
        );
        return { id => $file_id, path => $path, mime_type => $content_type };
    }
}

*open_file = *open_directory;

sub change_dir_prop
{
    my ($self, $baton, $name, $value) = @_;
    return unless defined $baton;
    my $file_id = $baton->{id};
    my $db = $self->{db};

    # Don't bother storing the special 'entry' properties.
    return if $name =~ /^svn:entry:/;

    # Keep track of the content type, so that we know whether to do anything
    # special with the file data like figure out the width and height of
    # image files.
    $baton->{mime_type} = trim($value)
        if $name eq 'svn:mime-type';

    # Store property changes for passing to custom property loaders when
    # the file or directory is closed.
    $baton->{props}{$name} = $value;

    # Store in the working copy.
    if (!defined $value) {
        db_delete($db, 'wc_property',
            file_id => $file_id,
            name => $name,
        );
    }
    else {
        db_replace($db, 'wc_property',
            { file_id => $file_id, name => $name },
            value => $value,
        );
    }

    # Handle changes to the 'daizu:generator' property specially, because it
    # might mean updating our children if they don't override it.
    if ($name eq 'daizu:generator') {
        if (defined $value) {
            my $generator = trim($value);
            die "bad 'daizu:generator' property, seems to be empty"
                if $generator eq '';

            # This will set all the children recursively, and also set the
            # generator and root file for this file.
            _update_generators($db, $file_id, $generator, $file_id);

            # But this is the root file, so unset the root file ID.
            db_update($db, wc_file => $file_id, root_file_id => undef);
        }
        else {
            # Property removed.  Make the file inherit its generator from
            # its parent.
            my ($generator, $root_file_id);
            my $parent_id = db_select($db, wc_file => $file_id, 'parent_id');
            if (defined $parent_id) {
                ($generator, $root_file_id) = db_select($db,
                    wc_file => $parent_id,
                    qw( generator root_file_id ),
                );
                $root_file_id = $parent_id
                    unless defined $root_file_id;
            }
            else {
                # We're a top-level file, so fall back to the default.
                $generator = 'Daizu::Gen';
                $root_file_id = $file_id;
            }

            assert(defined $root_file_id) if DEBUG;
            _update_generators($db, $file_id, $generator, $root_file_id);
        }
    }

    $baton->{changed} = 1;
}

*change_file_prop = *change_dir_prop;

sub absent_directory
{
    my ($self, $path) = @_;
    warn "file or directory '$path' cannot be updated for some reason";
}

*absent_file = *absent_directory;

sub close_directory
{
    my ($self, $baton) = @_;
    return unless defined $baton;
    my $props = $baton->{props};

    _automatic_modified_at($self->{db}, $baton->{id})
        if $baton->{changed};

    $self->{cms}->call_property_loaders($baton->{id}, $props)
        if keys %$props;

    _update_file_authors($self, $baton->{id}, $baton->{path}, $props, 1)
        if exists $props->{'daizu:author'};
}

sub add_file
{
    my ($self, $path, $baton) = @_;
    my $db = $self->{db};
    my $branch_path = $self->{branch_path};

    assert($branch_path eq substr($path, 0, length($branch_path))) if DEBUG;
    $path = substr($path, length($branch_path) + 1);

    my $guid = file_guid($db, $self->{branch_id}, $path, $self->{revnum});
    my $name = ($path =~ m!/([^/]+)\z!) ? $1 : $path;
    my ($issued, $modified) = guid_first_last_times($db, $guid->{id});

    my $parent_id = defined $baton ? $baton->{id} : undef;
    my ($generator, $root_file_id);
    if (defined $parent_id) {
        ($generator, $root_file_id) = db_select($db, wc_file => $parent_id,
                                                'generator', 'root_file_id');
        $root_file_id = $parent_id
            unless defined $root_file_id;
    }
    else {
        $generator = 'Daizu::Gen';
    }

    my $file_id = db_insert($db, 'wc_file',
        wc_id => $self->{wc_id},
        guid_id => $guid->{id},
        parent_id => $parent_id,
        name => $name,
        path => $path,
        is_dir => 0,
        issued_at => db_datetime($issued),
        modified_at => db_datetime($modified),
        cur_revnum => $self->{revnum},
        data => '',
        data_len => 0,
        data_sha1 => '2jmj7l5rSw0yVb/vlWAYkK/YBwk',     # SHA1 of empty string
        generator => $generator,
        root_file_id => $root_file_id,
    );
    return { id => $file_id, path => $path, added => 1 };
}

sub apply_textdelta
{
    my ($self, $baton, undef, $pool) = @_;
    assert(defined $baton) if DEBUG;
    assert(!defined $baton->{data}) if DEBUG;
    my $file_id = $baton->{id};
    my $path = $baton->{path};

    $baton->{changed} = 1;
    $self->{articles_to_reload}{$file_id} = undef;

    # If this file is included (via XInclude) in the content of any articles,
    # then those articles will have to be reloaded to get these changes.
    my $sth = $self->{db}->prepare(q{
        select file_id
        from wc_article_included_files
        where included_file_id = ?
    });
    $sth->execute($file_id);
    while (my ($id) = $sth->fetchrow_array) {
        $self->{articles_to_reload}{$id} = undef;
    }

    $baton->{data} = '';
    open my $out_fh, '>', \$baton->{data}
        or die "error opening in-memory file to store Subversion update: $!\n";
    my $orig_data = wc_file_data($self->{db}, $file_id);
    open my $in_fh, '<', $orig_data
        or die "error opening in-memory file for delta source: $!\n";
    return [ SVN::TxDelta::apply($in_fh, $out_fh, undef, $path, $pool) ];
}

sub close_file
{
    my ($self, $baton) = @_;
    my $db = $self->{db};
    assert(defined $baton) if DEBUG;

    my $file_id = $baton->{id};
    my $props = $baton->{props};

    if (defined $baton->{data}) {
        wc_set_file_data($self->{cms}, $self->{wc_id}, $file_id,
                         $baton->{mime_type}, \$baton->{data}, 1);
    }
    else {
        # If the 'svn:mime-type' property has been changed, that may mean we
        # need to store or unset the width and height of an image file.
        # Normally these values get set in 'wc_set_file_data', so this only
        # covers the case where the property is changed on an existing file
        # without the content also being changed.
        if (exists $props->{'svn:mime-type'}) {
            my $mime_type = $props->{'svn:mime-type'};
            if (defined $mime_type && $mime_type =~ m!^image/!i) {
                my $data = wc_file_data($db, $file_id);
                my ($img_wd, $img_ht) = imgsize($data);
                assert(!defined $img_wd || $img_wd > 0) if DEBUG;
                assert(!defined $img_ht || $img_ht > 0) if DEBUG;
                db_update($db, wc_file => $file_id,
                    image_width => $img_wd,
                    image_height => $img_ht,
                );
            }
            else {
                db_update($db, wc_file => $file_id,
                    image_width => undef,
                    image_height => undef,
                );
            }
        }
    }

    _automatic_modified_at($db, $file_id)
        if $baton->{changed};

    $self->{cms}->call_property_loaders($file_id, $props)
        if defined $props && keys %$props;

    if (exists $props->{'daizu:author'}) {
        _update_file_authors($self, $file_id, $baton->{path}, $props, 0);
    }
    else {
        $self->{file_authors_needs_init}{$baton->{path}} = $file_id
            if $baton->{added};
    }

    my $reload_article;

    # If any properties have changed, that may affect the article loader
    # plugin or the output that is stored from it (especially things like
    # 'dc:title', but for example 'daizu:alt' affects PictureArticles).
    $reload_article = 1
        if keys %$props;

    if (exists $props->{'daizu:type'}) {
        my $was_article = db_select($db, wc_file => $file_id, 'article');
        my $type = $props->{'daizu:type'};
        my $will_be_article = defined $type && trim($type) eq 'article';

        if ($will_be_article && !$was_article) {
            # Turn non-article into article.
            $reload_article = 1;
            db_update($db, wc_file => $file_id,
                article => 1,
                # These have to be given a non-NULL value, because of the
                # wc_file_article_loaded_chk constraint.  These values should
                # be gone by the time this transaction is committed.  This hack
                # is necessary because PostgreSQL, as of version 8.1, doesn't
                # support deferrable constraints other than for foreign keys.
                article_pages_url => 'AWAITING LOADING',
                article_content => 'AWAITING LOADING',
            );
        }
        elsif ($was_article && !$will_be_article) {
            # Turn article into non-article.
            $reload_article = 0;
            my %meta;
            while (my ($propname, $col) = each %Daizu::OVERRIDABLE_PROPERTY) {
                my $value = db_select($db, 'wc_property',
                    { file_id => $file_id, name => $propname },
                    'value',
                );
                $meta{$col} = trim_with_empty_null($value);
            }
            db_update($db, wc_file => $file_id,
                article => 0,
                article_pages_url => undef,
                article_content => undef,
                %meta,
            );
            db_delete($db, 'wc_article_extra_url', file_id => $file_id);
            db_delete($db, 'wc_article_extra_template', file_id => $file_id);
            db_delete($db, 'wc_article_included_files', file_id => $file_id);
        }
    }

    $self->{articles_to_reload}{$file_id} = undef
        if $reload_article;
}

sub abort_edit
{
    my ($self, $pool) = @_;
    # TODO
    print STDERR "abort_edit: self=$self, pool=$pool;\n";
}

sub close_edit
{
    my ($self) = @_;
    my $db = $self->{db};

    while (my ($path, $id) = each %{$self->{file_authors_needs_init}}) {
        _update_file_authors_for_new_file($self->{cms}, $db, $id);
    }

    for my $id (keys %{$self->{articles_to_reload}}) {
        Daizu::File->new($self->{cms}, $id)->update_loaded_article_in_db;
    }
}

# Bring 'modified_at' up to date, but only if a custom modified timestamp
# has been set, and is valid.
sub _automatic_modified_at
{
    my ($db, $file_id) = @_;

    # Don't do anything if the metadata specifies a custom modified time,
    # and that time is valid.
    my ($modified_at) = db_select($db, 'wc_property',
        { file_id => $file_id, name => 'dcterms:modified' },
        'value',
    );
    return if defined $modified_at &&
              defined validate_date($modified_at);

    # Set the timestamp to the time that the last change was committed.
    my ($modified) = $db->selectrow_array(q{
        select r.committed_at
        from revision r
        inner join file_guid g on g.last_changed_revnum = r.revnum
        inner join wc_file f on f.guid_id = g.id
        where f.id = ?
    }, undef, $file_id);
    assert(defined $modified) if DEBUG;

    db_update($db, wc_file => $file_id,
        modified_at => $modified,
    );
}

sub _update_file_authors
{
    my ($self, $file_id, $path, $props, $is_dir) = @_;
    my $db = $self->{db};
    my $extra = $self->{file_authors_needs_init};

    my $prop_value = $props->{'daizu:author'};
    $prop_value = Daizu::File->new($file_id)
                             ->most_specific_property('daizu:author')
        unless defined $prop_value;
    my @user;
    @user = split ' ', $prop_value
        if defined $prop_value;

    # Find the ID numbers associated with each username, and use those
    # from now on.
    if (@user) {
        my $id_sth = $db->prepare(q{
            select id
            from person
            where username = ?
        });

        for (@user) {
            $id_sth->execute($_);
            my ($user_id) = $id_sth->fetchrow_array;
            die "daizu:author contains unknown username '$_' on file $file_id"
                unless defined $user_id;
            $_ = $user_id;
        }
    }

    my $del_sth = $db->prepare(q{
        delete from file_author
        where file_id = ?
    });
    my $add_sth = $db->prepare(q{
        insert into file_author (file_id, person_id, pos) values (?, ?, ?)
    });
    my $author_sth = $db->prepare(q{
        select value
        from wc_property
        where file_id = ?
          and name = 'daizu:author'
    });

    if ($is_dir) {
        # Children which don't have their own daizu:author setting.
        my $child_sth = $db->prepare(q{
            select f.id, f.path, f.is_dir
            from wc_file f
            left outer join wc_property p on p.file_id = f.id
                                         and p.name = 'daizu:author'
            where parent_id = ?
              and p.value is null
        });
        _update_file_authors_for_dir($extra, $child_sth, $del_sth, $add_sth,
                                     $file_id, \@user);
    }
    else {
        _update_file_authors_for_file($extra, $del_sth, $add_sth,
                                      $file_id, $path, \@user);
    }
}

sub _update_file_authors_for_file
{
    my ($extra, $del_sth, $add_sth, $file_id, $path, $users) = @_;

    delete $extra->{$path};

    $del_sth->execute($file_id);

    my $n = 1;
    for (@$users) {
        $add_sth->execute($file_id, $_, $n++);
    }
}

sub _update_file_authors_for_dir
{
    my ($extra, $child_sth, $del_sth, $add_sth, $dir_id, $users) = @_;

    $child_sth->execute($dir_id);

    my @child_dirs;
    while (my ($id, $path, $is_dir) = $child_sth->fetchrow_array) {
        if ($is_dir) {
            push @child_dirs, $id;
        }
        else {
            _update_file_authors_for_file($extra, $del_sth, $add_sth,
                                          $id, $path, $users);
        }
    }

    for my $id (@child_dirs) {
        _update_file_authors_for_dir($extra, $child_sth, $del_sth, $add_sth,
                                     $id, $users);
    }
}

sub _update_file_authors_for_new_file
{
    my ($cms, $db, $file_id) = @_;

    # If the file does not have a 'daizu:author' property then the standard
    # loader won't be able to set up associations with it for authors set on
    # ancestor directories, so do that here.
    my $file = Daizu::File->new($cms, $file_id);
    my $author_prop = $file->most_specific_property('daizu:author');
    if (defined $author_prop && $author_prop =~ /\S/) {
        my $id_sth = $db->prepare(q{
            select id
            from person
            where username = ?
        });
        my $add_sth = $db->prepare(q{
            insert into file_author (file_id, person_id, pos)
                values (?, ?, ?)
        });

        my $n = 1;
        for my $username (split ' ', $author_prop) {
            $id_sth->execute($username);
            my ($user_id) = $id_sth->fetchrow_array;
            die "unknown user '$username' in daizu:author on file $file_id"
                unless defined $user_id;
            $add_sth->execute($file_id, $user_id, $n++);
        }
    }
}

sub _update_generators
{
    my ($db, $file_id, $generator, $root_file_id) = @_;

    db_update($db, wc_file => $file_id,
        generator => $generator,
        root_file_id => $root_file_id,
    );

    # If it's a directory, we have to also update its children, unless they
    # have their own generator override.
    my $is_dir = db_select($db, wc_file => $file_id, 'is_dir');
    return unless $is_dir;

    my $children = $db->selectcol_arrayref(q{
        select id
        from wc_file
        where parent_id = ?
          and root_file_id is not null
    }, undef, $file_id);
    assert(defined $children) if DEBUG;

    for my $id (@$children) {
        _update_generators($db, $id, $generator, $root_file_id);
    }
}

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

1;
# vi:ts=4 sw=4 expandtab
