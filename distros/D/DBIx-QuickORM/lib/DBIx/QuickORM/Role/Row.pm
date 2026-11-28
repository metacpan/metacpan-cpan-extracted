package DBIx::QuickORM::Role::Row;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak/;
use Hash::Util::FieldHash qw/fieldhash/;

use DBIx::QuickORM::LookupTable();

use Role::Tiny;

requires qw/orm table row_data set_row_data/;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Role::Row - The logic of a row object.

=head1 DESCRIPTION

A row object wraps one row's data (a hashref, as the ORM's CRUD operations
return it) with the ORM and the table it came from. C<raw_field> gives a value
as the database returned it. C<inflated_field>, and C<field>, give it
inflated through the field's type. A row in the database changes only through
C<update>, C<cas_update>, and C<delete>. There are no setters.

A row need not be in the database: one built by the ORM's C<vivify>, one
deleted, or one whose insert was rolled back. C<is_in_db> and C<was_deleted>
tell. Such a row is changed with C<modify> and written with C<insert>.
C<update>, C<cas_update>, C<delete>, and C<refresh> croak on it.

Inflated values are cached per field. When the row data is replaced (by
C<update>, C<refresh>, a field fetch that finds the row changed, or any call
of C<set_row_data>), cached values of fields whose raw value is unchanged are
kept and the rest are dropped.

A read hands out the cached value itself, or a copy of it, as the type says
(see L<DBIx::QuickORM::Role::Type/"Cached inflated values">), so changing a
value read from a row never changes the row or the next read.

A field missing from the row data was not fetched: it was omitted, or the row
came back from a write without C<RETURNING>. Reading it, in either form,
fetches every field asked for with one C<refresh_row>. When that shows the
row changed, the row takes the new row data, as C<refresh> would. Reading an
omitted field from each row in a loop can run one query per row.

A row that is not canon (from a C<no_cache> handle, say) fetches its missing
fields without the row cache: they are added to its own row data, nothing the
ORM holds changes, and the row stays not canon.

A row with no table (a row of a query, or a computed row given a row class)
returns the row data's values as they are from every field reader: no field
check, no inflation, and no fetch.

C<update>, C<cas_update>, and C<refresh> call the ORM's CRUD operations and
take the row data they return. C<delete> calls C<delete_row>. Options mean
what L<DBIx::QuickORM/"CRUD operations"> says.

Any class providing the required methods can consume the role. It keeps
nothing in the object. L<DBIx::QuickORM::Row> is the default row class.

=head2 Overriding

A row class changes what C<field> and C<fields> return by overriding them
(say, to give the raw form). It changes the cache policy by overriding
C<_inflation_cache> and C<_inflated_value>, the two supported override points.
Nothing else about the cache is.

=head1 SYNOPSIS

    package My::Row;
    use Object::HashBase qw{<orm <table row_data};
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::Row';

    # Raw values by default, but inflated_field and inflated_fields still inflate.
    sub field  { my $self = shift; $self->raw_field(@_) }
    sub fields { my $self = shift; $self->raw_fields(@_) }

    package main;

    my $orm = DBIx::QuickORM->new(
        credentials => \%credentials,
        row_class   => 'My::Row',
    );

    my $ann = $orm->insert(
        users => {
            name  => 'Ann',
            prefs => {theme => 'dark'},
        },
    );

    my $raw = $ann->field('prefs');             # the JSON text
    my $all = $ann->inflated_field('prefs');    # {theme => 'dark'}

=head1 REQUIRED METHODS

=over 4

=item $orm = $row->orm

The L<DBIx::QuickORM> the row came from.

=item $table = $row->table

The name of the row's table, or undef for a row with no table.

=item \%data = $row->row_data

The row data the row wraps.

=item $row->set_row_data(\%data)

Replaces the row data. The role calls it whenever the ORM returns new row
data for the row.

=back

=cut

# Inside-out, keyed by row object: {data => the row data the values came from, values => {field => inflated}}.
fieldhash my %CACHE;

=head1 PUBLIC METHODS

=over 4

=item $value = $row->field($name)

=item @values = $row->fields(\@names)

=item @values = $row->fields(@names)

The inflated form: C<inflated_field> and C<inflated_fields>. Override these
to give a row class another default form.

=back

=cut

sub field  { my $self = shift; $self->inflated_field(@_) }
sub fields { my $self = shift; $self->inflated_fields(@_) }

=pod

=over 4

=item $value = $row->inflated_field($name)

=item @values = $row->inflated_fields(\@names)

=item @values = $row->inflated_fields(@names)

Values inflated through each field's type: the cached value or a copy of it,
as the type says (see L</DESCRIPTION>). The raw value for an untyped field,
undef for NULL, and undef for an undef inflated value (a JSON C<null>).
Missing fields are fetched with one C<refresh_row> (one C<no_cache> read for a
row that is not canon). A row built by C<vivify>
returns undef for a field it was not given. So does a row whose insert
was rolled back.

Croaks for a field the table does not have, and for a missing field that
cannot be fetched (no primary key, or the row is deleted or no longer in the
database).

=back

=cut

# One field-record lookup. It calls _fetch_missing (which croaks for an unknown field) only when a field is unknown or missing.
sub inflated_field {
    my $self = shift;
    my ($name) = @_;

    my $table = $self->table;
    return $self->row_data->{$name} unless defined $table;

    my $field = $self->orm->db_map->table($table)->{fields}->{$name};
    $self->_fetch_missing($name) unless $field && exists $self->row_data->{$name};
    return $self->_inflated_value($name, $field);
}

sub inflated_fields {
    my $self  = shift;
    my @names = ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_;

    my $table = $self->table;
    return @{$self->row_data}{@names} unless defined $table;

    my $fields = $self->orm->db_map->table($table)->{fields};
    my $data   = $self->row_data;
    $self->_fetch_missing(@names) if grep { !$fields->{$_} || !exists $data->{$_} } @names;
    return map                            { $self->_inflated_value($_, $fields->{$_}) } @names;
}

=pod

=over 4

=item $raw = $row->raw_field($name)

=item @raw = $row->raw_fields(\@names)

=item @raw = $row->raw_fields(@names)

Values as the database returned them, never inflated. Missing fields are
fetched and unknown ones croak, as for C<inflated_fields>.

=back

=cut

sub raw_field {
    my $self = shift;
    my ($name) = @_;
    return ($self->raw_fields($name))[0];
}

sub raw_fields {
    my $self  = shift;
    my @names = ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_;
    $self->_fetch_missing(@names) if defined $self->table;
    return @{$self->row_data}{@names};
}

=pod

=over 4

=item \%pk = $row->pk

The primary key fields and their values from the row data. Undef when the row
has no table or the table has no primary key.

=back

=cut

sub pk {
    my $self  = shift;
    my $table = $self->table // return undef;
    my $pk    = $self->orm->db_map->pk($table) or return undef;
    my $data  = $self->row_data;
    return {map { $_ => $data->{$_} } @$pk};
}

=pod

=over 4

=item $row = $row->update(\%changes, %update_row_options)

Writes the changes with C<update_row> and takes the new row data. Returns the
row, or undef when no row matched (a compare-and-swap failed, or the row is
gone), leaving the row as it was.

Each change is deflated through its field's type. The options are those of
C<update_row>: C<enforce_canon>, C<cas>, C<auto_cas>. A row that is not
canonical croaks under C<enforce_canon>. C<cas_update> writes one safely.

Croaks when the changes are not a hashref, when given C<data> (it always
returns the row), when the row is not in the database, or when it has no
usable primary key.

=back

=cut

sub update {
    my $self = shift;
    my ($changes, %params) = @_;
    croak "update() needs a hashref of changes" unless ref($changes) eq 'HASH';
    croak "update() always returns the row; use the ORM's update_row() for row data" if exists $params{data};

    $self->_require_in_db('update');
    my $table = $self->_require_pk('update');
    my $orm   = $self->orm;
    return $orm->update_row($table, $self, $orm->connection->deflate($table, $changes), %params, raw => 1);
}

=pod

=over 4

=item $row = $row->cas_update(\%changes)

=item $row = $row->cas_update(\%changes, cas => \@fields)

Writes the changes only if the database still holds the row's values for the
changed fields (or the C<cas> fields). Returns the row with the new data, or
undef on a conflict, leaving the row as it was.

The row need not be canonical, even inside a transaction, so this is how
to write a row read before the transaction began. The changes are deflated as
C<update> deflates them.

It compares the changed fields with C<=>, which does not suit floats,
PostgreSQL C<json>, or MySQL C<JSON>: pass C<cas> to compare other fields. On
MySQL and MariaDB a successful update leaves only the primary key in the row
data, so another C<cas_update> croaks until the row is refreshed (or the
compared fields are read again).

Croaks when the changes are not a hashref of at least one change, on any
option but C<cas>, on an empty C<cas> list (an unconditional write), when the
row is not in the database, when it has no usable primary key, or when it does
not hold a field it compares.

=back

=cut

sub cas_update {
    my $self = shift;
    my ($changes, %params) = @_;
    croak "cas_update() needs a hashref of changes" unless ref($changes) eq 'HASH';
    croak "cas_update() takes only the 'cas' option" if grep { $_ ne 'cas' } keys %params;

    $self->_require_in_db('cas_update');
    my $table = $self->_require_pk('cas_update');
    my $orm   = $self->orm;
    croak "cas_update() needs a field to compare (an empty list would write unconditionally)" if ref($params{cas}) eq 'ARRAY' && !@{$params{cas}};
    my $cas = $params{cas} // [keys %$changes];
    return $orm->update_row($table, $self, $orm->connection->deflate($table, $changes), cas => $cas, enforce_canon => 0, raw => 1);
}

=pod

=over 4

=item $count = $row->delete(%delete_row_options)

Deletes the row with C<delete_row> and returns how many rows went. The row,
and every row holding the same row data, is then marked deleted.

A delete that matches no row also marks it deleted (it is not in the
database) and returns 0.

Croaks when the row is not in the database or has no usable primary key.

=back

=cut

sub delete {
    my $self = shift;
    my (%params) = @_;
    $self->_require_in_db('delete');
    my $table = $self->_require_pk('delete');
    return $self->orm->connection->delete_row($table, $self->row_data, %params, raw => 1);
}

=pod

=over 4

=item $row = $row->refresh

Reads the row from the database and takes the new row data. Takes no
arguments.

Croaks when given any, when the row is not in the database (as this ORM last
saw it), or has no usable primary key. Croaks too when the row is no longer
there, marking it deleted.

=back

=cut

sub refresh {
    my $self = shift;
    croak "refresh() takes no arguments" if @_;

    $self->_require_in_db('refresh');
    my $table = $self->_require_pk('refresh');
    return $self->orm->refresh_row($table, $self, cache => 0, raw => 1) // croak "The row is no longer in the table '$table'";
}

=pod

=over 4

=item $bool = $row->is_canon

True when the row data is the ORM's canonical copy of the row. False for a row
not in the database, even one without its key (the ORM's C<is_canon> croaks
for that). Croaks when a row in the database has no usable primary key.

=back

=cut

sub is_canon {
    my $self = shift;
    return 0 unless $self->is_in_db;
    my $table = $self->_require_pk('is_canon');
    return $self->orm->connection->is_canon($table, $self->row_data);
}

=over 4

=item $bool = $row->is_in_db

True unless the row was built by C<vivify> and not yet inserted, or was
marked deleted (see C<was_deleted>). This is what this ORM last saw, not a
check of the database.

C<insert> sets it. A rollback of the inserting transaction or savepoint
clears it again, so the row can be inserted again.

An update or refresh of that row in the same transaction carries this along.
A plain re-read that gives the row changed data does not: after a rollback
such a row may still report C<is_in_db>, so C<refresh> it to check.

=item $bool = $row->was_deleted

True when the row was marked deleted. Three things mark it: a row
C<delete>, a C<delete_row>, and a C<refresh> or C<find> that finds nothing in
the database.
A vivified row is neither in the database nor deleted.

A bulk C<delete> on a handle marks nothing unless given
C<< mark_deleted => 1 >>. Otherwise rows already held keep C<is_in_db> true,
so refresh them to check.

A delete inside a transaction or savepoint that rolls back is undone here too.

=back

=cut

sub is_in_db { DBIx::QuickORM::LookupTable->row_state($_[0]->row_data) ? 0 : 1 }

sub was_deleted {
    my $state = DBIx::QuickORM::LookupTable->row_state($_[0]->row_data) // '';
    return $state eq 'deleted' ? 1 : 0;
}

=pod

=over 4

=item $row = $row->insert

Inserts a row that is not in the database, with the ORM's C<insert>, and takes
the new row data. The row is then in the database, and canonical when the
table has a primary key. Returns the row.

Croaks when given arguments, for a row with no table, and for a row already
in the database.

=back

=cut

sub insert {
    my $self = shift;
    croak "insert() takes no arguments" if @_;
    my $table = $self->_require_table('insert');
    croak "Cannot insert a row that is already in the database (table '$table')" if $self->is_in_db;
    $self->set_row_data($self->orm->insert($table => $self->row_data, data => 1, raw => 1));
    return $self;
}

=pod

=over 4

=item $row = $row->modify(\%changes)

Changes the fields of a row that is not in the database, before its
C<insert>. Nothing is written. Returns the row.

The changes are deflated as C<update> deflates them. The row takes a changed
copy of its row data, so other rows holding the old row data are untouched.

Croaks when the changes are not a hashref, for a row with no table, for a
field the table does not have, and for a row in the database: use C<update>.

=back

=cut

sub modify {
    my $self = shift;
    my ($changes) = @_;
    croak "modify() needs a hashref of changes" unless ref($changes) eq 'HASH';
    my $table = $self->_require_table('modify');
    croak "Cannot modify a row that is in the database; use update()" if $self->is_in_db;

    my $old = $self->row_data;
    my $new = {%$old, %{$self->orm->connection->deflate($table, $changes)}};
    DBIx::QuickORM::LookupTable->copy_row_state($old, $new);
    $self->set_row_data($new);
    return $self;
}

=pod

=over 4

=item $h = $row->follow_fk($other_table, link => \%link)

=item $h = $row->follow_fk($other_table, via => \%via)

The ORM's C<follow_fk> from this row: a handle on the rows it links to.
Croaks for a row with no table.

=back

=cut

sub follow_fk {
    my $self = shift;
    my ($other, %params) = @_;
    my $table = $self->table;
    croak "Cannot follow a foreign key from a row with no table" unless defined $table;
    return $self->orm->_follow_fk([caller], $table, $self, $other, %params);
}

=pod

=over 4

=item $new = $row->insert_fk($other_table, %opts, \%fields)

=item \@new = $row->insert_many_fk($other_table, %opts, @fields)

The ORM's C<insert_fk> and C<insert_many_fk> from this row: insert rows that
point at it.

    my $post  = $alice->insert_fk('posts', {title => 'One'});
    my $posts = $alice->insert_many_fk('posts', link => {id => 'user_id'}, {title => 'A'}, {title => 'B'});

Croaks for a row with no table.

=back

=cut

sub insert_fk {
    my $self  = shift;
    my $table = $self->table;
    croak "Cannot insert rows linked to a row with no table" unless defined $table;
    return $self->orm->_insert_fk([caller], insert => $table, $self, @_);
}

sub insert_many_fk {
    my $self  = shift;
    my $table = $self->table;
    croak "Cannot insert rows linked to a row with no table" unless defined $table;
    return $self->orm->_insert_fk([caller], insert_many => $table, $self, @_);
}

=pod

=over 4

=item $bool = $class->fast_bless

True when the ORM may build rows of the class by blessing
C<< {orm => $orm, table => $table, row_data => \%data} >> directly, skipping
C<new>. False here. L<DBIx::QuickORM::Row> says when it is true.

The ORM takes the answer once per row class per ORM, not once per row.

=back

=cut

sub fast_bless { 0 }

=head1 PRIVATE METHODS

=over 4

=item $table = $row->_require_pk($action)

The row's table. Croaks naming the action unless the table has a primary key
and the row data holds all of it.

=back

=cut

sub _require_pk {
    my $self = shift;
    my ($action) = @_;

    my $table = $self->table;
    my $pk    = $self->pk;
    my $ok    = $pk && !grep { !defined } values %$pk;
    croak "Cannot $action a row without a primary key" . (defined($table) ? " (table '$table')" : '') unless $ok;

    return $table;
}

=pod

=over 4

=item $row->_require_in_db($action)

Croaks naming the action unless the row is in the database.

=item $table = $row->_require_table($action)

The row's table. Croaks naming the action for a row with no table.

=back

=cut

sub _require_in_db {
    my $self = shift;
    my ($action) = @_;
    croak "Cannot $action a row that is not in the database; insert it first" unless $self->is_in_db;
}

sub _require_table {
    my $self     = shift;
    my ($action) = @_;
    my $table    = $self->table;
    croak "Cannot $action a row with no table" unless defined $table;
    return $table;
}

=pod

=over 4

=item $row->_fetch_missing(@names)

Fetches the missing fields, all of them with one C<refresh_row> that also
asks for the fields already present, and takes the row data it returns. A vivified row fetches nothing: its missing fields
read as undef. Croaks for a field the table does not have, and for a deleted
row.

A row that is not canon reads just the missing fields through a C<no_cache>
handle and adds them to its own row data: the row cache is not touched, and
the row stays not canon.

=back

=cut

sub _fetch_missing {
    my $self = shift;
    my (@names) = @_;

    my $table  = $self->table;
    my $fields = $self->orm->db_map->table($table)->{fields};
    for my $name (@names) {
        croak "The table '$table' has no field '$name'" unless $fields->{$name};
    }

    my $data = $self->row_data;
    return unless grep { !exists $data->{$_} } @names;
    return if (DBIx::QuickORM::LookupTable->row_state($data) // '') eq 'vivified';
    $self->_require_in_db('fetch missing fields of');

    $self->_require_pk('fetch missing fields of');

    # A row that is not canon reads around the row cache and keeps its own data.
    unless ($self->is_canon) {
        my @missing = grep { !exists $data->{$_} } @names;
        my $got     = $self->orm->handle($table)->no_cache->fields(\@missing)->where($self->pk)->data_only->first or croak "Cannot fetch missing fields: the row is no longer in the table '$table'";
        $data->{$_} = $got->{$_} for @missing;
        return;
    }

    # The present fields are asked for too, so a changed row's new data holds them as well.
    my @want = ((grep { $fields->{$_} } keys %$data), @names);
    my $new  = $self->orm->connection->refresh_row($table, $data, fields => \@want, raw => 1) or croak "Cannot fetch missing fields: the row is no longer in the table '$table'";
    $self->set_row_data($new) unless $new == $data;
}

=pod

=over 4

=item \%values = $row->_inflation_cache

The cache of inflated values (field name to value) for the current row data.
A supported override point.

When the row data has been replaced since the cache was built, a new cache is
started, keeping the values of fields present in both whose raw values do not
differ by C<< DBIx::QuickORM::LookupTable->differ >>.

=back

=cut

sub _inflation_cache {
    my $self = shift;
    my $data = $self->row_data;
    my $old  = $CACHE{$self};
    return $old->{values} if $old && $old->{data} == $data;

    my %keep;
    if ($old) {
        my $was = $old->{data};
        for my $name (keys %{$old->{values}}) {
            next unless exists $data->{$name};
            next if DBIx::QuickORM::LookupTable->differ($was->{$name}, $data->{$name});
            $keep{$name} = $old->{values}->{$name};
        }
    }

    $CACHE{$self} = {data => $data, values => \%keep};
    return \%keep;
}

=pod

=over 4

=item $value = $row->_inflated_value($name, \%field)

The value to hand out for a present field. A supported override point.

The raw value when it is NULL, the field is untyped, or the field is
C<passthrough> (its type would return it unchanged). Otherwise the value
cached by C<_inflation_cache>, inflated on first read: as it is when the
type's C<inflated_is_immutable_for_cache> is true, or as C<clone_inflated>
copies it.

=back

=cut

sub _inflated_value {
    my $self = shift;
    my ($name, $field) = @_;

    my $raw  = $self->row_data->{$name};
    my $type = $field->{orm_type};
    return $raw unless defined($raw) && $type && !$field->{passthrough};

    my $cache = $self->_inflation_cache;
    $cache->{$name} = $type->inflate($raw, $field, $self->orm->connection) unless exists $cache->{$name};
    return $type->inflated_is_immutable_for_cache ? $cache->{$name} : $type->clone_inflated($cache->{$name});
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
