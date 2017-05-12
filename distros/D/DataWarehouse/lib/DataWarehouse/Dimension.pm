package DataWarehouse::Dimension;

use warnings;
use strict;

use Carp;
use Data::Dumper;
use DBI;

our $VERSION = '0.01';

sub new {
    my ( $class, %params ) = @_;

    croak "Error: One of 'dbh' or 'dsn' parameters is required" if !($params{dbh} xor $params{dsn});
    croak "Error: missing dimension name" if !$params{name};

    if ( $params{dsn} ) {
        $params{dbh} = DBI->connect( $params{dsn}, $params{db_user}, $params{db_password} ),;
    }

    bless {%params}, $class;
}

sub column_names {
    my ($self) = @_;

    my $table = $self->{name};
    warn $table;
    my $columns = $self->{dbh}->column_info( undef, undef, $table, '%' )->fetchall_arrayref();

    my @column_names = map { $_->[3] } @{$columns};
    return wantarray ? @column_names : \@column_names;
}

1;

__END__

=head1 NAME

DataWarehouse::Dimension - a data warehouse dimension meta-information

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use DataWarehouse::Dimension;

    # NOTE: "table" and "attributes" were not implemented yet

    my $dimension = DataWarehouse::Dimension->new(
        dbh   => $dbh,
        name  => 'product',
        table => 'product',
        attributes => [
            {
                name => 'id',
                PRIMARY_KEY => 1,
            },
            {
                name => 'product_id',
                NATURAL_KEY => 1,
            },
            {
                name => 'name',
                KEEP_HISTORY => 1,
                AGGREGATION_POINT => 1,
            },
            {
                name => 'brand'
                KEEP_HISTORY => 1,
                AGGREGATION_POINT => 1,
            },
            {
                name => 'price'
                KEEP_HISTORY => 1,
            },
        ],
    );

=head1 DESCRIPTION

Every dimensional model is made of Facts and Dimensions.

Facts are the measurements; for example, sales.

But the facts, per se, provide incomplete information: what is that
amount related to? Dimensions are give context to the facts. For
instance: "sales by country" or "sales by product", or "sales by
product, by day"

In relational databases, facts and dimensions will be stored in
separate tables; the result is the star schema:

         +-----+                       +-------------+
         ! day !-----             -----! salesperson !
         +-----+     \ +-------+ /     +-------------+
                       ! sales !
      +---------+    / +-------+ \     +----------+
      ! product !----             -----! customer !
      +---------+                      +----------+

=head2 PRIMARY KEY

Every dimension table must have a primary key that is different from
the primary key used in the source systems.

The primary key should be meaningless; we call it a "surrogate key".

=head2 NATURAL KEYS

You should also store the "natural key", used to identify the records
in the source systems: for example, product_id, customer_id, or
salesperson_id. You can identify the natural keys with
C<< NATURAL_KEY => 1 >>.

=head2 SLOWLY CHANGING DIMENSIONS

One of the major goals of the data warehouse is to preserve history. For
instance: a product could be priced at $259 in one year, and have a 
price drop to $189 in the next year.

You don't want to overwrite the price in the product dimension, because
that would cause you to loose information -- the old price was correct
in the past.

The strategy to deal with this, is to create a new record with the updated
information. That's why the data warehouse must use a surrogate key and 
should identify the natural keys.

You can identify the attributes for which you want to preserve history
with (C<< KEEP_HISTORY => 1 >>).

If you don't identify an attribute with C<<KEEP_HISTORY>>, we'll assume
that you don't want to preserve history for that information.

Finally, if you think that one attribute will change too often, you
should consider storing it in a separate dimension.

=head2 AGGREGATION POINTS

Some attributes are typically used as aggregation points, in many queries.

For instance: "month" and "year" are typical aggregate points in the
"day" dimension; "brand" and "type" are typical aggregation points in the
"product" dimension.

When you create a dimension, you can indicate that an attribute is an
aggregation point; this information may be used to generate aggregate
tables.

=head1 SEE ALSO

=over

=item *

L<DataWarehouse::Fact>

=back

=head1 AUTHOR

Nelson Ferraz, C<< <nferraz at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dw at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DataWarehouse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DataWarehouse::Dimension

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DataWarehouse>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DataWarehouse>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DataWarehouse>

=item * Search CPAN

L<http://search.cpan.org/dist/DataWarehouse/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Nelson Ferraz.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
