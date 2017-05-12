package DataWarehouse::Aggregate;

use warnings;
use strict;

use Carp;
use DBI;

sub new {
    my ( $class, %params ) = @_;

    croak "Error: One of 'dbh' or 'dsn' parameters is required" if !($params{dbh} xor $params{dsn});
    croak "Error: missing base_table" if !$params{base_table};
    croak "Error: missing dimension"  if !$params{dimension};

    if ( $params{dsn} ) {
        $params{dbh} = DBI->connect( $params{dsn}, $params{db_user}, $params{db_password} ),;
    }

    bless {%params}, $class;
}

sub dimension {
    my ($self) = @_;

    my $dimension = $self->{dimension};

    if ( ref $dimension eq 'ARRAY' ) {
        return @{$dimension};
    }

    return $dimension;
}

sub name {
    my ($self) = @_;

    my $base_table = $self->{base_table};
    my @dimensions = $self->dimension;

    my $name = "aggr_" . $self->{base_table} . "_" . join( '_', sort @dimensions );

    return $name;
}

sub create {
    my ($self) = @_;

    my $base_table = $self->{base_table};
    my @dimensions = $self->dimension;
    my $aggr_name  = $self->name;

    my $sql = <<"SQL";
CREATE TABLE IF NOT EXISTS $aggr_name AS
    SELECT
        @{[ join(', ', @dimensions ) ]},
        SUM(n) AS n
    FROM
        $base_table
    JOIN
@{[ join(",\n", map { $self->_join_str($_) } @dimensions) ]}
GROUP BY
    @{[ join(", ", @dimensions) ]}
SQL

    warn "Creating aggregate...\n";
    warn $sql;
    my $dbh = $self->{dbh};
    $dbh->do($sql);
    warn "done\n";

    return $self;
}

sub list {
}

sub _join_str {
    my ( $self, $dim_table ) = @_;
    my $fact_table = $self->{base_table};
    return "    $dim_table ON $fact_table.$dim_table = $dim_table.id";
}

1;

__END__

=head1 NAME

DataWarehouse::Aggregate - The great new DataWarehouse::Aggregate!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use DataWarehouse::Aggregate;

    my $foo = DataWarehouse::Aggregate->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Nelson Ferraz, C<< <nferraz at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dw at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DataWarehouse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DataWarehouse::Aggregate


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
