package DBIx::ResultSet;
BEGIN {
  $DBIx::ResultSet::VERSION = '0.17';
}
use Moose;
use namespace::autoclean;

=head1 NAME

DBIx::ResultSet - Lightweight SQL query building and execution.

=head1 SYNOPSIS

    use DBIx::ResultSet;
    
    # Same arguments as DBI and DBIx::Connector.
    my $connector = DBIx::ResultSet->connect(
        $dsn, $user, $pass,
        $attr, #optional
    );
    
    my $users = $connector->resultset('users');
    my $adult_users = $users->search({ age => {'>=', 18} });
    
    print 'Users: ' . $users->count() . "\n";
    print 'Adult users: ' . $adult_users->count() . "\n";

=head1 DESCRIPTION

This module provides an API that simplifies the creation and execution
of SQL queries.  This is done by providing a thin wrapper around
L<SQL::Abstract>, L<DBIx::Connector>, L<DBI>, L<Data::Page>, and the
DateTime::Format::* modules.

This module is not an ORM.  If you want an ORM use L<DBIx::Class>, it
is superb.

Some tips and tricks are recorded in the L<cookbook|DBIx::ResultSet::Cookbook>.

=cut

use Clone qw( clone );
use List::MoreUtils qw( uniq );
use Carp qw( croak );
use Data::Page;
use DBIx::ResultSet::Connector;

=head1 CONNECTING

In order to start using this module you must first configure the connection to your
database.  This is done using the connect() class method:

    # Same arguments as DBI and DBIx::Connector.
    my $connector = DBIx::ResultSet->connect(
        $dsn, $user, $pass,
        $attr, #optional
    );

The connect() class method is a shortcut for creating a L<DBIx::ResultSet::Connector>
object.  When created this way, the AutoCommit DBI attribute will default to 1.
This is done per the strong recommendations by L<DBIx::Connector/new>.

By default the underlying L<DBIx::Connector> object will be called with mode('fixup').
While not recommended, you can change the default connection mode by specifying the
ConnectionMode attribute, as in:

    my $connector = DBIx::ResultSet->connect(
        $dsn, $user, $pass,
        { ConnectionMode => 'ping' },
    );

Alternatively you could create a L<DBIx::ResultSet::Connector> object directly and
pass your own custom-rolled L<DBIx::Connector> object.  For example:

    my $dbix_connector = DBIx::Connector->new(
        $dsn, $username, $password,
        { AutoCommit => 1 },
    );
    my $connector = DBIx::ResultSet::Connector->new(
        dbix_connector => $dbix_connector,
    );

=cut

sub connect {
    my $self = shift;
    return DBIx::ResultSet::Connector->connect( @_ );
}

=head1 SEARCH METHODS

=head2 search

    my $old_rs = $connector->resultset('users')->search({ status => 0 });
    my $new_rs = $old_rs->search({ age > 18 });
    print 'Disabled adults: ' . $new_rs->count() . "\n";

Returns a new result set object that overlays the passed in where clause
on top of the old where clause, creating a new result set.  The original
result set's where clause is left unmodified.

search() never executes SQL queries.  You can call search() as many times
as you like and iteratively build a resultset as much as you want, but no
SQL will be issued until you call one of the L<manipulation|MANIPULATION METHODS>
or L<retrieval|RETRIEVAL METHODS> methods.

=cut

sub search {
    my ($self, $where, $clauses) = @_;

    $where ||= {};
    my $new_where = clone( $self->where() );
    map { $new_where->{$_} = $where->{$_} } keys %$where;

    my $new_clauses = {};
    foreach my $clause (uniq sort (keys %$clauses, keys %{$self->clauses()})) {
        if (exists $clauses->{$clause}) {
            $new_clauses->{$clause} = clone( $clauses->{$clause} );
        }
        else {
            $new_clauses->{$clause} = clone( $self->clauses->{$clause} );
        }
    }

    return ref($self)->new(
        connector => $self->connector(),
        table     => $self->table(),
        where     => $new_where,
        clauses   => $new_clauses,
    );
}

sub _dbi_execute {
    my ($self, $dbh_method, $sql, $bind, $dbh_attrs) = @_;

    return $self->connector->run(sub{
        my ($dbh) = @_;
        my $sth = $dbh->prepare_cached( $sql );
        if ($dbh_method eq 'do') {
            $sth->execute( @$bind );
        }
        else {
            return $dbh->$dbh_method( $sth, $dbh_attrs, @$bind );
        }
        return;
    });
}

sub _dbi_prepare {
    my ($self, $sql) = @_;

    return $self->connector->run(sub{
        my ($dbh) = @_;
        return $dbh->prepare_cached( $sql );
    });
}

sub _set_pager {
    my ($self) = @_;

    if ($self->clauses->{page}) {
        $self->clauses->{limit}  = $self->pager->entries_per_page();
        $self->clauses->{offset} = $self->pager->skipped();
    }

    return;
}

sub _do_select {
    my ($self, $fields) = @_;

    $self->_set_pager();
    my $clauses = $self->clauses();

    return $self->abstract->select(
        $self->table(), $fields, $self->where(),
        $clauses->{order_by},
        $clauses->{limit},
        $clauses->{offset},
    );
}

=head1 MANIPULATION METHODS

These methods create, change, or remove data.

=head2 insert

    $users_rs->insert(
        { user_name=>'bob2003', email=>'bob@example.com' }, # fields to insert
    );
    # Executes: INSERT INTO users (user_name, email) VALUES (?, ?);

Creates and executes an INSERT statement.

=cut

sub insert {
    my ($self, $fields) = @_;
    my ($sql, @bind) = $self->abstract->insert( $self->table(), $fields );
    $self->_dbi_execute( 'do', $sql, \@bind );
    return;
}

=head2 update

    $users_rs->update(
        { phone => '555-1234' }, # fields to update
    );
    # Executes: UPDATE users SET phone = ?;

    $users_rs->search({ is_admin=>1 })->update({ phone=>'555-1234 });
    # Executes: UPDATE users SET phone = ? WHERE is_admin = ?;

Creates and executes an UPDATE statement.

=cut

sub update {
    my ($self, $fields) = @_;
    my ($sql, @bind) = $self->abstract->update( $self->table(), $fields, $self->where() );
    $self->_dbi_execute( 'do', $sql, \@bind );
    return;
}

=head2 delete

    # Delete all users!
    $users_rs->delete();
    # Executes: DELETE FROM users;
    
    # Or just the ones that are disabled.
    users_rs->search({status=>0})->delete();
    # Executes: DELETE FROM users WHERE status = 0;

Creates and executes a DELETE statement.

=cut

sub delete {
    my ($self) = @_;
    my ($sql, @bind) = $self->abstract->delete( $self->table(), $self->where() );
    $self->_dbi_execute( 'do', $sql, \@bind );
    return;
}

=head2 auto_pk

    $users_rs->insert({ user_name=>'jdoe' });
    my $user_id = $users_rs->auto_pk();
    # Executes (MySQL):  SELECT LAST_INSERT_ID();
    # Executes (SQLite): SELECT LAST_INSERT_ROWID();
    # etc...

Currently only MySQL and SQLite are supported.  Oracle support will
be added soon, and other databases making their way in as needed.

=cut

sub auto_pk {
    my ($self) = @_;
    return $self->connector->_auto_pk( $self->table() );
}

=head1 RETRIEVAL METHODS

These methods provide common shortcuts for retrieving data.

=head2 array_row

    my $user = $users_rs->search({ user_id => 32 })->array_row(
        ['created', 'email', 'phone'], # optional, fields to retrieve
    );
    print $user->[1]; # email

Creates and executes a SELECT statement and then returns an
array reference.  The array will contain only the first row
that is retrieved, so you'll normally be doing this on a
resultset that has already been limited to a single row by
looking up by the table's primary key(s).

=cut

sub array_row {
    my ($self, $fields) = @_;
    my ($sql, @bind) = $self->_do_select( $fields );
    my @row = $self->_dbi_execute( 'selectrow_array', $sql, \@bind );
    return if !@row;
    return \@row;
}

=head2 hash_row

    my $user = $users_rs->search({ user_id => 32 })->hash_row(
        ['created', 'email', 'phone'], # optional, fields to retrieve
    );
    print $user->{email}; # email

This works just the same as array_row(), above, but instead
it returns a hash ref.

=cut

sub hash_row {
    my ($self, $fields) = @_;
    my ($sql, @bind) = $self->_do_select( $fields );
    return $self->_dbi_execute( 'selectrow_hashref', $sql, \@bind );
}

=head2 array_of_array_rows

    my $disabled_users = $users_rs->array_of_array_rows(
        ['user_id', 'email', 'phone'], # optional, fields to retrieve
    );
    print $disabled_users->[2]->[1];

Returns an array ref of array refs, one for each row returned.

=cut

sub array_of_array_rows {
    my ($self, $fields) = @_;
    my ($sql, @bind) = $self->_do_select( $fields );
    return $self->_dbi_execute( 'selectall_arrayref', $sql, \@bind );
}

=head2 array_of_hash_rows

    my $disabled_users = $rs->array_of_hash_rows(
        ['user_id', 'email', 'phone'], # optional, fields to retrieve
    );
    print $disabled_users->[2]->{email};

Returns an array ref of hash refs, one for each row.

=cut

sub array_of_hash_rows {
    my ($self, $fields) = @_;
    my ($sql, @bind) = $self->_do_select( $fields );
    return $self->_dbi_execute( 'selectall_arrayref', $sql, \@bind, { Slice=>{} } );
}

=head2 hash_of_hash_rows

    my $disabled_users = $rs->hash_of_hash_rows(
        'user_name',                                # column to key the hash by
        ['user_id', 'user_name', 'email', 'phone'], # optional, fields to retrieve
    );
    print $disabled_users->{jsmith}->{email};

Returns a hash ref where the key is the value of the column
that you specify as the first argument, and the value is a
hash ref contains that row's data.

=cut

sub hash_of_hash_rows {
    my ($self, $key, $fields) = @_;
    my ($sql, @bind) = $self->_do_select( $fields );
    return $self->connector->run(sub{
        my ($dbh) = @_;
        my $sth = $dbh->prepare_cached( $sql );
        return $dbh->selectall_hashref( $sth, $key, {}, @bind );
    });
}

=head2 count

    my $total_users = $users_rs->count();

Returns that number of records that match the resultset.

=cut

sub count {
    my ($self) = @_;
    return $self->pager->entries_on_this_page() if $self->clauses->{page};
    my ($sql, @bind) = $self->_do_select( 'COUNT(*)' );
    return ( $self->_dbi_execute( 'selectrow_array', $sql, \@bind ) )[0];
}

=head2 column

    my $user_ids = $users_rs->column(
        'user_id', # column to retrieve
    );
    print 'User IDs: ' . join( ', ', @$user_ids );

Returns an array ref containing a single column's value for all
matching rows.

=cut

sub column {
    my ($self, $column) = @_;
    my ($sql, @bind) = $self->_do_select( $column );
    return $self->_dbi_execute( 'selectcol_arrayref', $sql, \@bind );
}

=head1 STH METHODS

Get L<DBI> statement handles when you have more specialized
needs.

=head2 select_sth

    my ($sth, @bind) = $rs->select_sth(
        ['user_name', 'user_id'], # optional, fields to retrieve
    );
    $sth->execute( @bind );
    $sth->bind_columns( \my( $user_name, $user_id ) );
    while ($sth->fetch()) { ... }

If you want a little more power, or want you DB access a little more
effecient for your particular situation, then you might want to get
at the select sth.

=cut

sub select_sth {
    my ($self, $fields) = @_;
    my ($sql, @bind) = $self->_do_select( $fields );
    return( $self->_dbi_prepare( $sql ), @bind );
}

=head2 insert_sth

    my $insert_sth;
    foreach my $user_name (qw( jsmith bthompson gfillman )) {
        my $fields = {
            user_name => $user_name,
            email     => $user_name . '@mycompany.com',
        };

        $insert_sth ||= $rs->insert_sth(
            $fields, # fields to insert
        );

        $insert_sth->execute(
            $rs->bind_values( $fields ),
        );
    }

If you're going to insert a *lot* of records you probably don't want to
be re-generating the SQL every time you call insert().

=cut

sub insert_sth {
    my ($self, $fields) = @_;
    my ($sql, @bind) = $self->abstract->insert( $fields );
    return $self->_dbi_prepare( $sql );
}

=head2 bind_values

This mehtod calls L<SQL::Abstract>'s values() method.  Normally this
will be used in conjunction with insert_sth().

=cut

sub bind_values {
    my ($self, $fields) = @_;
    return $self->abstract->values( $fields );
}

=head1 SQL METHODS

These methods just produce SQL, allowing you to have complete
control of how it is executed.

=head2 select_sql

    my ($sql, @bind) = $users_rs->select_sql(
        ['email', 'age'], # optional, fields to retrieve
    );

Returns the SQL and bind values for a SELECT statement.  This is
useful if you want to handle DBI yourself, or for building subselects.
See the L<DBIx::ResultSet::Cookbook> for examples of subselects.

=cut

sub select_sql {
    my ($self, $fields) = @_;
    return $self->_do_select( $fields );
}

=head2 where_sql

    my ($sql, @bind) = $users_rs->search({ title => 'Manager' })->where_sql();

This works just like select_sql(), but it only returns the
WHERE portion of the SQL query.  This can be useful when you are
doing complex joins where you need to write raw SQL, but you still
want to build up your WHERE clause without writing SQL.

Note, that if order_by, limit, offset, rows, or page clauses or specified
then the returned SQL will include those clauses as well.

=cut

sub where_sql {
    my ($self) = @_;
    $self->_set_pager();
    my $clauses = $self->clauses();
    return $self->abstract->where(
        $self->where(),
        $clauses->{order_by},
        $clauses->{limit},
        $clauses->{offset},
    );
}

=head1 ATTRIBUTES

=head2 connector

The L<DBIx::ResultSet::Connector> object that this resultset
is bound too.

=cut

has 'connector' => (
    is       => 'ro',
    isa      => 'DBIx::ResultSet::Connector',
    required => 1,
    handles => [qw(
        dbh
        run
        txn
        svp
        abstract
    )],
);

=head2 pager

    my $rs = $connector->resultset('users')->search({}, {page=>2, rows=>50});
    my $pager = $rs->pager(); # a pre-populated Data::Page object

A L<Data::Page> object pre-populated based on page() and rows().  If
page() has not been specified then trying to access page() will throw
an error.

The total_entries and last_page methods are proxied from the pager in
to this class so that you can call:

    print $rs->total_entries();

Instead of:

    print $rs->pager->total_entries();

=cut

has 'pager' => (
    is         => 'ro',
    isa        => 'Data::Page',
    lazy_build => 1,
    init_arg   => undef,
    handles => [qw(
        total_entries
        last_page
    )],
);
sub _build_pager {
    my ($self) = @_;

    croak 'pager() can only be called on pageing result sets' if !$self->clauses->{page};

    my $pager = Data::Page->new();
    $pager->total_entries( $self->search({}, {page=>0})->count() );
    $pager->entries_per_page( $self->clauses->{rows} || 10 );
    $pager->current_page( $self->clauses->{page} );

    return $pager;
}

=head2 table

The name of the table that this result set will be using for queries.

=cut

has 'table' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 where

The where clause hash ref to be used when executing queries.

=cut

has 'where' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub{ {} },
);

=head2 clauses

Additional clauses, such as order_by, limit, offset, etc.

=cut

has 'clauses' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub{ {} },
);

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 SEE ALSO

=over

=item * L<DBIx::Class::ResultSet::HashRef>

=back

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

