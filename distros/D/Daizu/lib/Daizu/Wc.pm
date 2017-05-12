package Daizu::Wc;
use warnings;
use strict;

use Carp qw( croak );
use Carp::Assert qw( assert DEBUG );
use Daizu::Wc::UpdateEditor;
use Daizu::File;
use Daizu::Util qw(
    db_datetime
    db_row_exists db_row_id db_select db_insert db_update transactionally
    mint_guid guess_mime_type wc_set_file_data
    branch_id
);

=head1 NAME

Daizu::Wc - access to database working copies

=head1 DESCRIPTION

Objects of this class provide methods for accessing the data in Daizu CMS
database working copies.

=head1 METHODS

=over

=item Daizu::Wc-E<gt>new($cms, $id)

Return an object representing a working copy in the database, given its
ID number.  The default if no working copy ID is given is the
working copy which represents the state of the live web content (usually
working S<copy 1>).

=cut

sub new
{
    my ($class, $cms, $id) = @_;
    croak "bad working copy ID number '$id'"
        if defined $id && $id !~ /^\d+$/;
    $id = $cms->{live_wc_id}
        if !defined $id;

    my ($branch_id, $branch_path) = $cms->{db}->selectrow_array(q{
        select wc.branch_id, b.path
        from working_copy wc
        inner join branch b on b.id = wc.branch_id
        where wc.id = ?
    }, undef, $id);
    croak "working copy '$id' does not exist"
        unless defined $branch_id;

    return bless {
        cms => $cms,
        id => $id,
        branch_id => $branch_id,
        branch_path => $branch_path,
    }, $class;
}

=item Daizu::Wc-E<gt>checkout($cms, $branch, $revnum)

Creates a new working copy on C<$branch> (either the ID number or path
of a known branch) and updates it to revision C<$revnum> (or the latest
revision if that is C<undef>).

Returns a C<Daizu::Wc> object for accessing it.

=cut

sub checkout
{
    my ($class, $cms, $branch, $revnum) = @_;
    return transactionally($cms->{db}, \&_checkout_txn,
                           $class, $cms, $branch, $revnum);
}

sub _checkout_txn
{
    my ($class, $cms, $branch, $revnum) = @_;
    my $db = $cms->{db};

    my $branch_id = branch_id($db, $branch);
    my $branch_path = db_select($db, branch => $branch_id, 'path');

    my $latest_revnum = $cms->load_revision($revnum);
    $revnum = $latest_revnum unless defined $revnum;

    my $wc_id = db_insert($db, working_copy =>
        branch_id => $branch_id,
        current_revision => $revnum,
    );

    my $editor = Daizu::Wc::UpdateEditor->new(
        cms => $cms,
        db => $db,
        wc_id => $wc_id,
        revnum => $revnum,
        branch_id => $branch_id,
        branch_path => $branch_path,
    );
    my $reporter = $cms->{ra}->do_update($revnum, $branch_path, 1, $editor);
    $reporter->set_path('', 0, 1, undef);
    $reporter->finish_report;

    return $class->new($cms, $wc_id);
}

=item $wc-E<gt>id

Return the ID number of the working copy.

=cut

sub id { $_[0]->{id} }

=item $wc-E<gt>current_revision

Return the number of the revision which the working copy is currently
updated to.

=cut

sub current_revision
{
    my ($self) = @_;
    return db_select($self->{cms}{db}, working_copy => $self->{id},
                     'current_revision');
}

=item $wc-E<gt>file_at_path($path)

Return a L<Daizu::File> object representing the file or directory which
currently resides at C<$path> in the working copy.  Dies if there is no
such file.

=cut

sub file_at_path
{
    my ($self, $path) = @_;
    my $file_id = db_row_id($self->{cms}{db}, 'wc_file',
        wc_id => $self->{id},
        path => $path,
    );
    croak "no file at '$path' in working copy $self->{id}"
        unless defined $file_id;
    return Daizu::File->new($self->{cms}, $file_id);
}

=item $wc->update($revnum)

Update a database working copy to revision C<$revnum>.  This is done in a
transaction, which will be rolled back if anything goes wrong, leaving the
WC in its original state.  C<$revnum> can be C<undef> to update to the most
recent revision available.

=cut

sub update
{
    my ($self, $revnum) = @_;
    return transactionally($self->{cms}{db}, \&_update_txn, $self, $revnum);
}

sub _update_txn
{
    my ($self, $revnum) = @_;
    my $cms = $self->{cms};
    my $db = $cms->{db};

    my $latest_revnum = $cms->load_revision($revnum);
    $revnum = $latest_revnum unless defined $revnum;

    my $cur_revnum = $self->current_revision;
    return $cur_revnum
        if $cur_revnum >= $revnum;

    my $editor = Daizu::Wc::UpdateEditor->new(
        cms => $self->{cms},
        db => $db,
        wc_id => $self->{id},
        revnum => $revnum,
        branch_id => $self->{branch_id},
        branch_path => $self->{branch_path},
    );
    my $reporter = $cms->{ra}->do_update($revnum, $self->{branch_path}, 1,
                                         $editor);
    $reporter->set_path('', $cur_revnum, 0, undef);
    $reporter->finish_report;

    db_update($db, working_copy => $self->{id},
        current_revision => $revnum,
    );

    $db->do(q{
        update wc_file
        set cur_revnum = ?
        where cur_revnum is not null
          and not modified
          and not deleted
    }, undef, $revnum);

    return $revnum;
}

=item $wc-E<gt>add_file($path, $data)

TODO - this method isn't safe to use yet, and will corrupt the working copy.

=cut

sub add_file
{
    my ($self, $path, $data) = @_;
    my $wc_id = $self->{id};
    croak "you're not allowed to make changes in the live working copy"
        if $wc_id == $self->{cms}{live_wc_id};

    my $db = $self->{cms}{db};
    $db->begin_work;

    if (db_row_exists($db, 'wc_file', wc_id => $wc_id, path => $path)) {
        $db->rollback;
        croak "file or directory already exists at path '$path' in WC $wc_id";
    }

    my ($parent_id, $name);
    if ($path =~ m!^(.*)/([^/]+)!) {
        $name = $2;
        $parent_id = db_row_id($db, 'wc_file',
            path => $1,
            is_dir => 1,
        );
        croak "parent directory '$1' does not exist"
            unless defined $parent_id;
    }
    else {
        $parent_id = undef;
        $name = $path;
    }

    my $mime_type = guess_mime_type($data, $path);

    my ($guid_id) = mint_guid($self->{cms}, 0, $path, 1);   # TODO, revnum
    my $file_id = db_insert($db, 'wc_file',
        wc_id => $wc_id,
        guid_id => $guid_id,
        parent_id => $parent_id,
        is_dir => 0,
        name => $name,
        path => $path,
        modified_at => db_datetime(DateTime->now),
        content_type => $mime_type,
        data => '',
        data_len => 0,
        data_sha1 => '2jmj7l5rSw0yVb/vlWAYkK/YBwk',
    );
    wc_set_file_data($self->{cms}, $wc_id, $file_id, $mime_type, $data, 0);

    $db->commit;
    return $file_id;
}

=item $wc-E<gt>add_directory($path)

TODO - this method isn't safe to use yet, and will corrupt the working copy.

=cut

sub add_directory
{
    my ($self, $path) = @_;
    my $wc_id = $self->{id};
    croak "you're not allowed to make changes in the live working copy"
        if $wc_id == $self->{cms}{live_wc_id};

    my $db = $self->{cms}{db};
    $db->begin_work;

    if (db_row_exists($db, 'wc_file', wc_id => $wc_id, path => $path)) {
        $db->rollback;
        croak "file or directory already exists at path '$path' in WC $wc_id";
    }

    my ($parent_id, $name);
    if ($path =~ m!^(.*)/([^/]+)!) {
        $name = $2;
        $parent_id = db_row_id($db, 'wc_file',
            path => $1,
            is_dir => 1,
        );
        croak "parent directory '$1' does not exist"
            unless defined $parent_id;
    }
    else {
        $parent_id = undef;
        $name = $path;
    }

    my ($guid_id) = mint_guid($self->{cms}, 1, $path, 1);   # TODO, revnum
    my $file_id = db_insert($db, 'wc_file',
        wc_id => $wc_id,
        guid_id => $guid_id,
        parent_id => $parent_id,
        is_dir => 1,
        name => $name,
        path => $path,
        modified_at => db_datetime(DateTime->now),
        data_len => 0,
    );

    $db->commit;
    return $file_id;
}

=item $wc-E<gt>change_file_content($file_id, $data)

TODO - this method isn't safe to use yet, and will corrupt the working copy.

=cut

sub change_file_content
{
    my ($self, $file_id, $data) = @_;
    my $name = db_select($self->{cms}{db}, wc_file => $file_id, 'name');
    my $mime_type = guess_mime_type($data, $name);
    wc_set_file_data($self->{cms}, $self->{id}, $file_id, $mime_type, $data, 0);
}

=item $wc-E<gt>change_property($file_id, $name, $value)

TODO - this method isn't safe to use yet, and will corrupt the working copy.

=cut

sub change_property
{
    my ($self, $file_id, $name, $value) = @_;
    my $db = $self->{cms}{db};
    my $prop_id = db_row_id($db, 'wc_property',
        file_id => $file_id,
        name => $name,
    );

    if (!defined $value) {
        # Delete
        croak "can't delete non-existent property '$name' on file $file_id"
            unless defined $prop_id;
        db_update($db, wc_file => { file_id => $file_id, name => $name },
            deleted => 1,
        );
    }
    elsif (!defined $prop_id) {
        # Add
        db_insert($db, 'wc_file',
            file_id => $file_id,
            name => $name,
            value => $value,
            modified => 1,
        );
    }
    else {
        # Modify
        db_update($db, wc_file => { file_id => $file_id, name => $name },
            modified => 1,
            value => $value,
        );
    }
}

=item $wc->commit

TODO - this doesn't do anything yet

=cut

sub commit
{
    my ($self) = @_;
    my $db = $self->{cms}{db};
    my $ra = $self->{cms}{ra};

    $db->begin_work;

    my $sth = $db->prepare(q{
        select path, modified, deleted
        from wc_file
        where wc_id = ?
        order by path
    });
    $sth->execute($self->{id});
}

=back

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

1;
# vi:ts=4 sw=4 expandtab
