package DataWarehouse::Fact;

use warnings;
use strict;

our $VERSION = '0.04';

use Carp;
use Data::Dumper;
use DBI;

use DataWarehouse::Dimension;
use DataWarehouse::Aggregate;

use List::MoreUtils qw/uniq/;

sub new {
    my ( $class, %params ) = @_;

    croak "Error: One of 'dbh' or 'dsn' parameters is required" if !($params{dbh} xor $params{dsn});
    croak "Error: missing fact name" if !$params{name};

    if ( $params{dsn} ) {
        $params{dbh} = DBI->connect( $params{dsn}, $params{db_user}, $params{db_password} );
    }

    bless {%params}, $class;
}

sub dimension {
    my ( $self, $dim_table ) = @_;

    return DataWarehouse::Dimension->new(
        dbh  => $self->{dbh},
        name => $dim_table,
    );
}

sub aggregate {
    my ( $self, @dimensions ) = @_;

    return DataWarehouse::Aggregate->new(
        dbh        => $self->{dbh},
        base_table => $self->{name},
        dimension  => \@dimensions,
    );
}

sub base_query {
    my ( $self, $dim_attr, $where ) = @_;

    # @dim_attr is a list of "table.columns"
    my $fact_table = $self->{name};
    my @dim_attr   = @{$dim_attr};
    my @dim_tables = uniq( map { ( split( /\./, $_ ) )[0] } @dim_attr );

    my $query = <<"SQL";
SELECT
    @{[ join(", ", @dim_attr) ]},
    SUM(n) AS n
FROM
    $fact_table
JOIN
@{[ join(",\n", map { $self->_join_str($_) } @dim_tables) ]}
GROUP BY
    @{[ join(", ", @dim_attr) ]}
SQL

    return $query;

    my $dbh = $self->{dbh};

    my $sth = $dbh->prepare($query);

    my $rv = $sth->execute() or die $dbh->errstr;

    return $sth->fetchall_arrayref();
}

sub aggr_query {
    my ( $self, $dim_attr, $where ) = @_;

    my $base_query = $self->base_query( $dim_attr, $where );

    my @dim_attr = @{$dim_attr};
    my @dim_tables = uniq( map { ( split( /\./, $_ ) )[0] } @dim_attr );

    # don't aggregate the full granularity
    return $base_query if scalar @dim_attr == scalar @{ $self->{dimension} };

    my $aggregate = $self->aggregate(@dim_tables);

    # only necessary if the aggregate
    # does not exist
    $aggregate->create();

    my $fact_table = $self->{name};
    my $aggr_table = $aggregate->name();

    if ($aggr_table) {
        $base_query =~ s/$fact_table/$aggr_table/gs;
    }

    return $base_query;
}

sub prepare {
    my $self = shift;

    $self->{sth} = $self->{dbh}->prepare(@_);

    return $self->{sth};
}

sub _join_str {
    my ( $self, $dim_table ) = @_;
    my $fact_table = $self->{name};
    return "    $dim_table ON $fact_table.$dim_table = $dim_table.id";
}

1;

__END__
=head1 NAME

DataWarehouse::Fact - a Data Warehouse Fact table

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    use DataWarehouse::Fact;

    my $fact = DataWarehouse::Fact->new(
        dsn       => 'dbi:SQLite:dbname=dw.db',
        name      => 'sales',
        dimension => [ qw/ customer product / ],
    );

    my $query = $fact->aggr_query(
        \@dimension,
        \@where, 
    );

    my $sth = $fact->prepare($query);

    my $data = $sth->fetchall_arrayref();

=head1 DESCRIPTION

A DataWarehouse::Fact represents a fact table.

A typical fact table contains numeric facts and foreign keys that
references dimension tables. Some fact tables may contain just foreign
keys; those are "factless" fact tables. Fact tables may also contain
natural keys that identify the facts in the source systems.

=head2 GRAIN

The grain of a fact table is defined by its dimensions. For instance,
the grain of "Sales" fact table is "Sales by product, by store, by day".

This notion is particularly useful when we talk about aggregate fact
tables, which different grain (for example: "Sales by month").

=head2 HOUSEKEEPING COLUMNS

=head3 load_date

When a fact is loaded, it should have a timestamp that identifies the
load time. This will help us to detect aggregate tables which should 
be updated.

=head3 n

When we create aggregate tables, we will store the number of aggregated
records in a column called "n". For the base fact table, n should default
to 1.

=head1 AUTHOR

Nelson Ferraz, C<< <nferraz at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dw at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DataWarehouse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DataWarehouse::Fact

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
