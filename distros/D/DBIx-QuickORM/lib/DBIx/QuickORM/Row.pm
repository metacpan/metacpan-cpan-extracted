package DBIx::QuickORM::Row;
use strict;
use warnings;

our $VERSION = '0.000031';

use Object::HashBase qw{
    <orm
    <table
    row_data
};

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Row';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Row - The default row class.

=head1 DESCRIPTION

L<DBIx::QuickORM::Role::Row> applied to a class, and nothing more. The ORM
builds rows with this class unless told otherwise (C<row_class> in
L<DBIx::QuickORM>). Subclass it to add methods to a table's rows.

=head1 SYNOPSIS

    my $bob  = $orm->insert(users => {name => 'Bob'});
    my $name = $bob->field('name');
    $bob->update({name => 'Robert'});

=head1 ATTRIBUTES

=over 4

=item $orm = $row->orm

The L<DBIx::QuickORM> the row came from.

=item $table = $row->table

The name of the row's table, or undef for a row with no table.

=item \%data = $row->row_data

=item $row->set_row_data(\%data)

The row data the row wraps. C<update>, C<refresh>, and field fetches replace
it. Setting it directly is supported but rarely needed.

=back

=head1 USING ROWS

The methods below come from L<DBIx::QuickORM::Role::Row>, which documents
each in full.

=head2 Read fields

    my $user = $orm->find(users => $id);

    my $name           = $user->field('name');
    my ($nick, $email) = $user->fields('name', 'email');
    my $theme          = $user->field('prefs')->{theme};                 # inflated: JSON as Perl data
    my $json           = $user->raw_field('prefs');                      # as the database returned it
    my $year           = $user->field('created')->datetime_ref->year;    # a DateTime, built on first use

C<field> gives the inflated form, as does C<inflated_field>. C<raw_field>
never inflates. Each has a plural form taking several names.

=head2 Change a row

Rows have no setters. Change a row with C<update>, which writes to the
database and takes the new data:

    # a copy: changing it changes neither the row nor the database
    my $prefs = $user->field('prefs');
    $prefs->{theme} = 'light';
    $user->update({
        prefs => $prefs,
        name  => 'Alice Smith',
    });

    # Only while email still holds what this row read. Undef otherwise.
    my $ok = $user->update({email => 'alice@example.org'}, cas => ['email']);

    $user->refresh;                  # read it again from the database
    my $deleted = $user->delete;     # 1

=head2 Fields not fetched yet

A row can lack fields: the handle asked for only some, or the database could
not return the whole row after a write. Reading one fetches every field asked
for with one C<refresh_row>.

    my $slim = $orm->handle('users')
        ->fields(['name'])
        ->where({name => 'Bob'})
        ->only;

    my $email = $slim->field('email');    # fetched now

In a loop that is one query per row, so select the fields up front instead.

=head2 Follow foreign keys

    my $post   = $orm->handle('posts')->where({title => 'Hello'})->only;
    my $author = $post->follow_fk('users')->only;              # one row
    my @posts  = $author->follow_fk('posts')->all;             # many rows
    my @busy   = $author->follow_fk('posts')->and({views => {'>' => 100}})->all;

=head2 Insert linked rows

    my $reply = $author->insert_fk('posts', {title => 'Reply'});    # user_id is filled in
    my $more  = $author->insert_many_fk('posts', {title => 'A'}, {title => 'B'});

=head2 Keys and canonical data

    my $pk   = $post->pk;          # {id => 1}
    my $data = $post->row_data;    # the row's data as a hashref: read it, never change it

    unless ($post->is_canon) {
        $post->refresh;
    }

C<is_canon> is true while the row's data is the ORM's canonical copy. It
stops being so when another row object or a bulk write changes the row, when
the ORM's cache is cleared, and inside a transaction begun after the row was
read. Writing (an update or a delete) a row that is not canonical croaks,
unless C<enforce_canon> is off: refresh it first, or update it with
C<cas_update>, which writes only while the database still holds what the row
read.

=head2 Add your own methods

Subclass this class and name it for a table:

    package My::User;
    use parent 'DBIx::QuickORM::Row';

    sub display_name {
        my $self  = shift;
        my $email = $self->field('email');
        return $self->field('name') . (defined($email) ? " <$email>" : '');
    }

    package main;

    my $orm = DBIx::QuickORM->new(
        credentials => \%credentials,
        row_classes => {users => 'My::User'},
    );

    my $who = $orm->insert(users => {name => 'Carol'})->display_name;

=head1 PUBLIC METHODS

A row has every method of L<DBIx::QuickORM::Role::Row>, which documents them:
C<orm>, C<table>, C<row_data>, C<set_row_data>, C<field>, C<fields>,
C<inflated_field>, C<inflated_fields>, C<raw_field>, C<raw_fields>, C<pk>,
C<update>, C<cas_update>, C<delete>, C<refresh>, C<is_canon>, C<is_in_db>,
C<was_deleted>, C<insert>, C<modify>, C<follow_fk>, C<insert_fk>, and
C<insert_many_fk>. It overrides one, C<fast_bless>:

=over 4

=item $bool = $class->fast_bless

True when the class builds rows exactly as a plain bless would: it has no
C<init> (nor HashBase pre- or post-init hooks), and its C<new> is still this
class's. The ORM then blesses rows directly, which is faster.
The ORM takes the answer once per row class per ORM.

A subclass that adds an C<init> or its own C<new> gets false, so its rows go
through C<new>.

=back

=cut

sub fast_bless {
    my $class = shift;
    $class = ref($class) || $class;

    return 0 if $class->can('init');
    return 0 unless ($class->can('new') // 0) == \&DBIx::QuickORM::Row::new;
    my @hooks = ($class->_pre_init, $class->_post_init);
    return @hooks ? 0 : 1;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
