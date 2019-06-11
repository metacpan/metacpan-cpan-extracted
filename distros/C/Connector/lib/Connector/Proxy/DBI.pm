# Connector::Proxy::DBI
#
# Proxy class for fetching a value from using DBI
#
# Written by Oliver Welter and Martin Bartosch for the OpenXPKI project 2013

package Connector::Proxy::DBI;

use strict;
use warnings;
use English;
use DBI;
use Data::Dumper;

use Moose;
extends 'Connector::Proxy';


has dbuser => (
    is  => 'rw',
    isa => 'Str',
);

has password => (
    is  => 'rw',
    isa => 'Str',
);

has table => (
    is  => 'rw',
    isa => 'Str',
);

has column => (
    is  => 'rw',
    isa => 'Str|HashRef',
);

has condition => (
    is  => 'rw',
    isa => 'Str',
);

has ambiguous => (
    is  => 'rw',
    isa => 'Str',
    default => 'empty',
);

has _dbi => (
    is  => 'ro',
    isa => 'Object',
    lazy => 1,
    builder => '_dbi_handle'
);


sub _dbi_handle {

    my $self = shift;

    my $dsn = $self->LOCATION();

    my $dbh;
    eval {
        $dbh = DBI->connect($dsn, $self->dbuser(), $self->password(),
        { RaiseError => 1, LongReadLen => 1024 });
    };

    if ($EVAL_ERROR || !$dbh) {
        $self->log()->error('DBI connect failed. DSN: '.$dsn. ' - Error: ' . $EVAL_ERROR );
        die "DBI connect failed."
    }
    return $dbh;

}

sub get {

    my $self = shift;
    my @path = $self->_build_path( shift );

    my $column = $self->column();
    if (!$column || ref $column ne '') {
        die "column must be a singe column name when using get";
    }

    my $query = sprintf "SELECT %s FROM %s WHERE %s",
        $column, $self->table(), $self->condition();

    $self->log()->debug('Query is ' . $query);

    my $sth = $self->_dbi()->prepare($query);
    $sth->execute( @path );

    my $row = $sth->fetchrow_arrayref();

    $self->log()->trace('result is ' . Dumper $row );

    my $result;
    if (!$row) {
        return $self->_node_not_exists( @path );

    } elsif (($self->ambiguous() ne 'return') && $sth->fetchrow_arrayref()) {

        $self->log()->error('Ambiguous (multi-valued) result');
        if ($self->ambiguous() eq 'die') {
            die "Ambiguous (multi-valued) result";
        }
        return $self->_node_not_exists( @path );

    }

    $self->log()->debug('Valid return: ' . $row->[0]);
    return $row->[0];

}

sub get_hash {

    my $self = shift;
    my @path = $self->_build_path( shift );

    my $column = $self->column();
    if ($column && ref $column ne 'HASH') {
        die "column must be a hashref or empty when using get_hash";
    }

    my $columns = '*';
    if (ref $column eq 'HASH') {
        my @cols;
        map {
            push @cols, sprintf( "%s as %s", $column->{$_}, $_ );
        } keys %{$column};
        $columns = join(",", @cols);
    }

    my $query = sprintf "SELECT %s FROM %s WHERE %s",
        $columns, $self->table(), $self->condition();

    $self->log()->debug('Query is ' . $query);

    my $sth = $self->_dbi()->prepare($query);
    $sth->execute( @path );

    my $row = $sth->fetchrow_hashref();

    $self->log()->trace('result is ' . Dumper $row );

    if (!$row) {
        return $self->_node_not_exists( @path );

    } elsif (($self->ambiguous() ne 'return') && $sth->fetchrow_hashref()) {

        $self->log()->error('Ambiguous (multi-valued) result');
        if ($self->ambiguous() eq 'die') {
            die "Ambiguous (multi-valued) result";
        }
        return $self->_node_not_exists( @path );
    }

    $self->log()->debug('Valid return: ' . Dumper $row);
    return $row;

}


sub get_list {

    my $self = shift;
    my @path = $self->_build_path( shift );


    my $column = $self->column();
    if (!$column || ref $column ne '') {
        die "column must be a singe column name when using get_list";
    }

    my $query = sprintf "SELECT %s FROM %s WHERE %s",
        $self->column(), $self->table(), $self->condition();

    $self->log()->debug('Query is ' . $query);

    my $sth = $self->_dbi()->prepare($query);
    $sth->execute( @path );

    my $rows = $sth->fetchall_arrayref();

    # hmpf
    unless (ref $rows eq 'ARRAY') {
       $self->log()->error('DBI did not return an arrayref');
       die "DBI did not return an arrayref.";
    }

    if (scalar @{$rows} == 0) {
        return $self->_node_not_exists( @path );
    }
    my @result;
    foreach my $row (@{$rows}) {
       push @result, $row->[0];
    }

    $self->log()->trace('result ' . Dumper \@result);

    $self->log()->debug('Valid return, '. scalar @result .' lines');
    return @result;

}

sub get_size {

    my $self = shift;
    my @path = $self->_build_path( shift );

    my $query = sprintf "SELECT COUNT(*) as count FROM %s WHERE %s",
        $self->table(), $self->condition();

    $self->log()->debug('Query is ' . $query);

    my $sth = $self->_dbi()->prepare($query);
    $sth->execute( @path );

    my $row = $sth->fetchrow_arrayref();

    $self->log()->trace('Result is ' . Dumper $row);

    return $row->[0];

}

sub get_meta {

    my $self = shift;

    # If we have no path, we tell the caller that we are a connector
    my @path = $self->_build_path( shift );
    if (scalar @path == 0) {
        return { TYPE  => "connector" };
    }

    # can be used as scalar also but list will be fine in any case
    return { TYPE => 'list' };
}


# Will not catch get with an ambigous result :(
sub exists {

    my $self = shift;

    # No path = connector root which always exists
    my @path = $self->_build_path( shift );
    if (scalar @path == 0) {
        return 1;
    }

    return $self->get_size( \@path ) > 0;

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head 1 Name

Connector::Proxy::DBI

=head 1 Description

Use DBI to make a query to a database.

=head1 Usage

=head2 Configuration

    my $con = Connector::Proxy::DBI->new({
        LOCATION => 'DBI:mysql:database=openxpki;host=localhost',
        dbuser => 'queryuser',
        password => 'verysecret',
        table => 'mytable',
        column => 1,
        condition => 'id = ?',
        ambiguous => 'die',
    });

=head2 Parameters

=over

=item dbuser

=item password

=item table

The name of the table, can also be a JOIN clause (if supported by the driver).

=item column

For get/get_list the name of a single column to be returned.

For get_hash a hash where the keys are the target keys of the resulting
hash and the values are the column names.

=item condition

The condition using a question mark as placeholder. The placeholder(s) are
fed from the path components.

=item ambigous

Controls the behaviour of the connector if more than one result is found
when a single one is expected (get/get_hash).

=over

=item empty (default)

Return an empty result, will also die if I<die_on_undef> is set.

=item return

The potential ambiguity is ignored and the first row fetched is returned.
Note that depending on the database backend the actual result returned from
the is very likely undetermined.

=item die

Die with an error message.

=back

=back

=head1 Methods

=head2 get

Will return the value of the requested column of the matching row. If no row
is found, undef is returned (dies if die_on_undef is set).

If multiple rows are found, behaviour depends on the value of I<ambiguous>.

=head2 get_list

Will return the selected column of all matching lines as a list. If no match is
found undef is returned (dies if die_on_undef is set).

=head2 get_meta

Will return scalar if the query has one result or list if the query has
multiple rows. Returns undef if no rows are found.

=head2 get_hash

Return a single row as hashref, by default all columns are returned as
retrieved from the database. Pass a hashref to I<column>, where the key
is the target key and the value is the name of the column you need.

E.g. when your table has the columns id and name but you need the keys
index and title in your result.

    $con->column({ 'id' => 'id', '`index`' => 'id', 'title' => 'name' });

Note: The mapping is set directly on the sql layer and as escaping
reserved words is not standardized, we dont do it. You can add escape
characters yourself to the column map where required, as shown for the
word "index" in the given example.

=head2 get_keys

not supported


