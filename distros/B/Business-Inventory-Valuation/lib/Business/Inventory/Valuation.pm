package Business::Inventory::Valuation;

our $DATE = '2018-03-09'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub new {
    my $class = shift;
    my %args = @_;

    my $self = bless {}, $class;
    die "Please specify method" unless $args{method};
    die "Invalid method, please choose LIFO/FIFO"
        unless $args{method} =~ /\A(LIFO|FIFO)\z/;
    $self->{method} = delete $args{method};

    keys(%args) and die "Unknown argument(s): ".join(", ", keys %args);

    $self->{_inventory} = [];
    $self->{_total_units}    = 0;
    $self->{_avg_unit_price} = undef;

    $self;
}

sub buy {
    my ($self, $units, $unit_price) = @_;

    # sanity checks
    die "Units must be > 0" unless $units > 0;
    die "Unit price must be >= 0" unless $unit_price >= 0;

    push @{ $self->{_inventory} }, [$units, $unit_price];
    if (@{ $self->{_inventory} } == 1) {
        $self->{_total_units}    = $units;
        $self->{_avg_unit_price} = $unit_price;
    } else {
        my $oldtotal = $self->{_total_units};
        $self->{_total_units}   += $units;
        $self->{_avg_unit_price} = (
            $oldtotal * $self->{_avg_unit_price} +
                $units * $unit_price) / $self->{_total_units};
    }
}

sub sell {
    my ($self, $units, $unit_price) = @_;

    # sanity checks
    die "Units must be > 0" unless $units > 0;
    die "Unit price must be >= 0" unless $unit_price >= 0;
    die "Attempted to oversell ($units, while inventory only has ".
        "$self->{_total_units})" unless $self->{_total_units} >= $units;

    while (@{ $self->{_inventory} }) {
        my $item;
        if ($self->{method} eq 'LIFO') {
            $item = $self->{_inventory}[-1];
        } else {
            $item = $self->{_inventory}[0];
        }
        if ($item->[0] > $units) {
            $item->[0] -= $units;
            my $oldtotal = $self->{_total_units};
            $self->{_total_units} -= $units;
            $self->{_avg_unit_price} = (
                $oldtotal * $self->{_avg_unit_price} -
                    $units*$item->[1]) / $self->{_total_units};
            return;
        } else {
            if ($self->{method} eq 'LIFO') {
                pop @{ $self->{_inventory} };
            } else {
                shift @{ $self->{_inventory} };
            }
            $units -= $item->[0];
            my $oldtotal = $self->{_total_units};
            $self->{_total_units} -= $item->[0];
            if ($self->{_total_units} == 0) {
                undef $self->{_avg_unit_price};
            } else {
                $self->{_avg_unit_price} = (
                    $oldtotal * $self->{_avg_unit_price} -
                        $item->[0]*$item->[1]) / $self->{_total_units};
            }
            return if $units == 0;
        }
    }
}

sub inventory {
    my $self = shift;
    @{ $self->{_inventory} };
}

sub summary {
    my $self = shift;
    ($self->{_total_units}, $self->{_avg_unit_price});
}


1;
# ABSTRACT: Calculate inventory value/unit price (using LIFO or FIFO)

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::Inventory::Valuation - Calculate inventory value/unit price (using LIFO or FIFO)

=head1 VERSION

This document describes version 0.001 of Business::Inventory::Valuation (from Perl distribution Business-Inventory-Valuation), released on 2018-03-09.

=head1 SYNOPSIS

 use Business::Inventory::Valuation;

 my $biv = Business::Inventory::Valuation->new(
     method                   => 'LIFO', # required. choose LIFO/FIFO
 );

 my ($units, $avgprice, @inv);

 # buy: 100 units @1500
 $biv->buy (100, 1500);
 @inv = $biv->inventory;              # => ([100, 1500])
 ($units, $avgprice) = $biv->summary; # => (100, 1500)

 # buy more: 150 units @1600
 $biv->buy (150, 1600);
 @inv = $biv->inventory;              # => ([100, 1500], [150, 1600])
 ($units, $avgprice) = $biv->summary; # => (250, 1560)

 # sell: 50 units @1700
 $biv->sell( 25, 1700);
 @inv = $biv->inventory;              # => ([100, 1500], [100, 1600])
 ($units, $avgprice) = $biv->summary; # => (200, 1550)

 # buy: 200 units @1500
 $biv->buy(200, 1500);
 @inv = $biv->inventory;              # => ([100, 1500], [100, 1600], [200, 1500])
 ($units, $avgprice) = $biv->summary; # => (400, 1525)

 # sell: 350 units @1800
 $biv->sell(350, 1800);
 @inv = $biv->inventory;              # => ([50, 1500])
 ($units, $avgprice) = $biv->summary; # => (50, 1500)

 # sell: 60 units @1700
 $biv->sell(60, 1800);                # dies!

=head1 DESCRIPTION

This module can be used if you want to calculate average purchase price from a
series of purchases each with different prices (like when buying stocks or
cryptocurrencies) or want to value your inventory using LIFO/FIFO method.

Keywords: average purchase price, inventory valuation, FIFO, LIFO.

=head1 METHODS

=head2 new

Usage: Business::Inventory::Valuation->new(%args) => obj

Known arguments:

=over

=item * method => str ("LIFO"|"FIFO")

=back

=head2 buy

Usage: $biv->buy($units, $unit_price)

=head2 sell

Usage: $biv->buy($units, $unit_price)

Will die if C<$units> exceeds the number of units in inventory.

=head2 summary

Usage: $biv->summary => ($units, $avg_unit_price)

If inventory is empty, will return C<<(0, undef)>>.

=head2 inventory

Usage: $biv->inventory => @ary

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Business-Inventory-Valuation>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Business-Inventory-Valuation>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Business-Inventory-Valuation>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
