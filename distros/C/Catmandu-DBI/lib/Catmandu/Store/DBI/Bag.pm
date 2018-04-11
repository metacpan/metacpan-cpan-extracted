package Catmandu::Store::DBI::Bag;

use Catmandu::Sane;
use Moo;
use Catmandu::Store::DBI::Iterator;
use namespace::clean;

our $VERSION = "0.0702";

my $default_mapping = {
    _id => {
        column   => 'id',
        type     => 'string',
        index    => 1,
        required => 1,
        unique   => 1,
    },
    _data => {column => 'data', type => 'binary', serialize => 'all',}
};

has mapping => (is => 'ro', default => sub {+{%$default_mapping}},);

has _iterator => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_iterator',
    handles => [
        qw(
            generator
            count
            slice
            select
            detect
            first
            )
    ],
);

with 'Catmandu::Bag';
with 'Catmandu::Serializer';

sub BUILD {
    my ($self) = @_;
    $self->_normalize_mapping;

    # TODO should happen lazily;
    $self->store->handler->create_table($self);
}

sub _normalize_mapping {
    my ($self) = @_;
    my $mapping = $self->mapping;

    $mapping->{_id} ||= $default_mapping->{_id};

    for my $key (keys %$mapping) {
        my $map = $mapping->{$key};
        $map->{type}   ||= 'string';
        $map->{column} ||= $key;
    }

    $mapping;
}

sub _build_iterator {
    my ($self) = @_;
    Catmandu::Store::DBI::Iterator->new(bag => $self);
}

sub get {
    my ($self, $id) = @_;
    my $store      = $self->store;
    my $dbh        = $store->dbh;
    my $q_name     = $dbh->quote_identifier($self->name);
    my $q_id_field = $dbh->quote_identifier($self->mapping->{_id}->{column});
    my $sth
        = $dbh->prepare_cached(
        "SELECT * FROM ${q_name} WHERE ${q_id_field}=?")
        or Catmandu::Error->throw($dbh->errstr);
    $sth->execute($id) or Catmandu::Error->throw($sth->errstr);
    my $row = $sth->fetchrow_hashref;
    $sth->finish;
    $self->_row_to_data($row // return);
}

sub add {
    my ($self, $data) = @_;
    $self->store->handler->add_row($self, $self->_data_to_row($data));
    $data;
}

sub delete {
    my ($self, $id) = @_;
    my $store      = $self->store;
    my $dbh        = $store->dbh;
    my $q_name     = $dbh->quote_identifier($self->name);
    my $q_id_field = $dbh->quote_identifier($self->mapping->{_id}->{column});
    my $sth
        = $dbh->prepare_cached("DELETE FROM ${q_name} WHERE ${q_id_field}=?")
        or Catmandu::Error->throw($dbh->errstr);
    $sth->execute($id) or Catmandu::Error->throw($sth->errstr);
    $sth->finish;
}

sub delete_all {
    my ($self) = @_;
    my $store  = $self->store;
    my $dbh    = $store->dbh;
    my $q_name = $dbh->quote_identifier($self->name);
    my $sth    = $dbh->prepare_cached("DELETE FROM ${q_name}")
        or Catmandu::Error->throw($dbh->errstr);
    $sth->execute or Catmandu::Error->throw($sth->errstr);
    $sth->finish;
}

sub _row_to_data {
    my ($self, $row) = @_;
    my $mapping = $self->mapping;
    my $data    = {};

    for my $key (keys %$mapping) {
        my $map = $mapping->{$key};
        my $val = $row->{$map->{column}} // next;
        if ($map->{serialize}) {
            $val = $self->deserialize($val);
            if ($map->{serialize} eq 'all') {
                for my $k (keys %$val) {
                    $data->{$k} = $val->{$k} // next;
                }
                next;
            }
        }
        if ($map->{type} eq "datetime") {

            my ($date, $time) = split ' ', $val;
            $val = "${date}T${time}Z";

        }
        $data->{$key} = $val;
    }

    $data;
}

sub _data_to_row {
    my ($self, $data) = @_;
    $data = {%$data};
    my $mapping = $self->mapping;
    my $row     = {};
    my $serialize_all_column;

    for my $key (keys %$mapping) {
        my $map = $mapping->{$key};
        my $val = delete($data->{$key});
        if ($map->{serialize}) {
            if ($map->{serialize} eq 'all') {
                $serialize_all_column = $map->{column};
                next;
            }
            $val = $self->serialize($val // next);
        }
        if ($map->{type} eq "datetime") {

            # Translate ISO dates into datetime format
            if ($val && $val =~ /^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})/) {
                $val = "$1 $2";
            }
        }
        $row->{$map->{column}} = $val // next;
    }

    if ($serialize_all_column) {
        $row->{$serialize_all_column} = $self->serialize($data);
    }

    $row;
}

=head1 NAME

Catmandu::Store::DBI::Bag - implementation of a Catmandu::Bag for DBI

=head1 SYNOPSIS

    my $store = Catmandu::Store::DBI->new(
        data_source => "dbi:SQLite:dbname=/tmp/test.db",
        bags => {
            data => {
                mapping => {
                    _id => {
                        column => 'id',
                        type => 'string',
                        index => 1,
                        unique => 1
                    },
                    author => {
                        type => 'string'
                    },
                    subject => {
                        type => 'string',
                    },
                    _data => {
                        column => 'data',
                        type => 'binary',
                        serialize => 'all'
                    }
                }
            }
        }
    );

    my $bag = $store->bag('data');

    #SELECT
    {
        #SELECT * FROM DATA WHERE author = 'Nicolas'
        my $iterator = $bag->select( author => 'Nicolas' );
    }
    #CHAINED SELECT
    {
        #SELECT * FROM DATA WHERE author = 'Nicolas' AND subject = 'ICT'
        my $iterator = $bag->select( author => 'Nicolas' )->select( subject => 'ICT' );
    }
    #COUNT
    {
        #SELECT * FROM DATA WHERE author = 'Nicolas'
        my $iterator = $bag->select( author => 'Nicolas' );

        #SELECT COUNT(*) FROM ( SELECT * FROM DATA WHERE author = 'Nicolas' )
        my $count = $iterator->count();
    }
    #DETECT
    {
        #SELECT * FROM DATA WHERE author = 'Nicolas' AND subject = 'ICT' LIMIT 1
        my $record = $bag->select( author => 'Nicolas' )->detect( subject => 'ICT' );
    }

    #NOTES
    {

        #This creates an iterator with a specialized SQL query:

        #SELECT * FROM DATA WHERE author = 'Nicolas'
        my $iterator = $bag->select( author => 'Nicolas' );

        #But this does not
        my $iterator2 = $iterator->select( title => "Hello world" );

        #'title' does not have a corresponding table column, so it falls back to the default implementation,
        #and loops over every record.

    }
    {

        #this is faster..
        my $iterator = $bag->select( author => 'Nicolas' )->select( title => 'Hello world');

        #..than
        my $iterator2 = $bag->select( title => 'Hello world' )->select( author => 'Nicolas' );

        #reason:

        #   the select statement of $iterator creates a specialized query, and so reduces the amount of records to loop over.
        #   $iterator is a L<Catmandu::Store::DBI::Iterator>.

        #   the select statement of $iterator2 does not have a specialized query, so it's a generic L<Catmandu::Iterator>.
        #   the second select statement of $iterator2 receives this generic object as its source, and can only loop over its records.

    }

=head1 DESCRIPTION

Catmandu::Store::DBI::Bag provides some method overrides specific for DBI interfaces,
to make querying more efficient.

=head1 METHODS

=head2 select($key => $val)

Overrides equivalent method in L<Catmandu::Bag>.

Either returns a generic L<Catmandu::Iterator> or a more efficient L<Catmandu::Store::DBI::Iterator>.

Expect the following behaviour:

=over 4

=item

the key has a corresponding table column configured

a SQL where clause is created in the background:

.. WHERE $key = $val

Chained select statements with existing table columns result in a combined where clause:

    .. WHERE $key1 = $val1 AND $key2 = $val2 ..

The returned object is a L<Catmandu::Store::DBI::Iterator>, instead of the generic L<Catmandu::Iterator>.

=item

the key does not have a corresponding table column configured

The returned object is a generic L<Catmandu::Iterator>.

This iterator can only loop over the records provided by the previous L<Catmandu::Iterable>.

=back

A few important notes:

=over 4

=item

A select statement only results in a L<Catmandu::Store::DBI::Iterator>, when it has a mapped key,
and the previous iterator is either a L<Catmandu::Store::DBI::Bag> or a L<Catmandu::Store::DBI::Iterator>.

=item

As soon as the returned object is a generic L<Catmandu::Iterator>, any following select statement
with mapped columns will not make a more efficient L<Catmandu::Store::DBI::Iterator>.

=back

In order to make your chained statements efficient, do the following:

=over 4

=item

create indexes on the table columns

=item

put select statements with mapped keys in front, and those with non mapped keys at the end.

=back

To configure table columns, see L<Catmandu::Store::DBI>.

=head2 detect($key => $val)

Overrides equivalent method in L<Catmandu::Bag>.

Also returns first record where $key matches $val.

Works like the select method above, but adds the SQL statement 'LIMIT 1' to the current SQL query in the background.

=head2 first()

Overrides equivalent method in L<Catmandu::Bag>.

Also returns first record using the current iterator.

The parent method uses a generator, but fetches only one record.

This method adds the SQL statement 'LIMIT 1' to the current SQL query.

=head2 count()

Overrides equivalent method in L<Catmandu::Bag>.

When the source is a L<Catmandu::Store::DBI::Bag>, or a L<Catmandu::Store::DBI::Iterator>,
a specialized SQL query is created:

    SELECT COUNT(*) FROM TABLE WHERE (..)

The select statement of the source is between the parenthesises.

=cut

1;
