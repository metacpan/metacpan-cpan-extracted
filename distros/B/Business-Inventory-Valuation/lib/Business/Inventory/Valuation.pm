package Business::Inventory::Valuation;

our $DATE = '2018-03-17'; # DATE
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;

sub new {
    my $class = shift;
    my %args = @_;

    my $self = bless {}, $class;

    die "Please specify method" unless $args{method};
    die "Invalid method, please choose LIFO/FIFO/weighted average"
        unless $args{method} =~ /\A(LIFO|FIFO|weighted average)\z/;
    $self->{method} = delete $args{method};

    $self->{allow_negative_inventory} = delete $args{allow_negative_inventory};

    keys(%args) and die "Unknown argument(s): ".join(", ", keys %args);

    $self->{_inventory} = [];
    $self->{_units} = 0;
    $self->{_average_purchase_price} = undef;

    $self;
}

sub buy {
    my ($self, $units, $unit_price) = @_;

    # sanity checks
    die "Units must be > 0" unless $units > 0;
    die "Unit price must be >= 0" unless $unit_price >= 0;

    if (!@{ $self->{_inventory} }) {
        push @{ $self->{_inventory} }, [$units, $unit_price];
        $self->{_units} = $units;
        $self->{_average_purchase_price} = $unit_price;
    } elsif (@{ $self->{_inventory} } && $self->{_inventory}[-1][1] == $unit_price) {
        my $old_units = $self->{_units};
        $self->{_inventory}[-1][0] += $units;
        $self->{_units} += $units;
        $self->{_average_purchase_price} = (
            $old_units * $self->{_average_purchase_price} +
                $units * $unit_price) / $self->{_units};
    } elsif ($self->{method} eq 'weighted average') {
        my $old_units = $self->{_units};
        $self->{_inventory}[0][0] = $self->{_units} = $self->{_units} + $units;
        $self->{_inventory}[0][1] = $self->{_average_purchase_price} = (
            $old_units * $self->{_average_purchase_price} +
                $units * $unit_price) / $self->{_units};
    } else {
        push @{ $self->{_inventory} }, [$units, $unit_price];
        my $old_units = $self->{_units};
        $self->{_units}+= $units;
        $self->{_average_purchase_price} = (
            $old_units * $self->{_average_purchase_price} +
                $units * $unit_price) / $self->{_units};
    }
}

sub sell {
    my ($self, $units, $unit_price) = @_;

    # sanity checks
    die "Units must be > 0" unless $units > 0;
    die "Unit price must be >= 0" unless $unit_price >= 0;

    my $profit = 0;
    my $units_sold = 0;

    if ($self->{_units} < $units) {
        if ($self->{allow_negative_inventory}) {
            $units = $self->{_units};
        } else {
            die "Attempted to oversell ($units, while inventory only has ".
                "$self->{_units})";
        }
    }

    my $remaining = $units;
    my $orig_average_purchase_price = $self->{_average_purchase_price};

    # due to rounding error, _units and _inventory might disagree for a bit
    while ($self->{_units} > 0 && @{ $self->{_inventory} } && $remaining > 0) {
        my $item;
        if ($self->{method} eq 'LIFO') {
            $item = $self->{_inventory}[-1];
        } else {
            $item = $self->{_inventory}[0];
        }

        if ($item->[0] > $remaining) {
            # inventory item is not used up
            my $old_units = $self->{_units};
            $item->[0] -= $remaining;
            $self->{_units} -= $remaining;
            if ($self->{_units} == 0) {
                undef $self->{_average_purchase_price};
            } else {
                $self->{_average_purchase_price} = (
                    $old_units * $self->{_average_purchase_price} -
                        $remaining * $item->[1]) / $self->{_units};
            }
            $profit += $remaining * ($unit_price - $item->[1]);
            $units_sold += $remaining;
            $remaining = 0;
            goto RETURN;
        } else {
            # inventory item is used up, remove from inventory
            if ($self->{method} eq 'LIFO') {
                pop @{ $self->{_inventory} };
            } else {
                shift @{ $self->{_inventory} };
            }
            $units_sold += $item->[0];
            $remaining -= $item->[0];
            my $old_units = $self->{_units};
            $self->{_units} -= $item->[0];
            $profit += $item->[0] * ($unit_price - $item->[1]);
            if ($self->{_units} == 0) {
                undef $self->{_average_purchase_price};
            } else {
                $self->{_average_purchase_price} = (
                    $old_units * $self->{_average_purchase_price} -
                        $item->[0] * $item->[1]) / $self->{_units};
            }
        }
    }

  RETURN:
    my @return;
    if (defined $orig_average_purchase_price) {
        push @return, $units *
            ($unit_price - $orig_average_purchase_price);
    } else {
        push @return, undef;
    }
    push @return, $profit;
    push @return, $units_sold;
    @return;
}

sub inventory {
    my $self = shift;
    @{ $self->{_inventory} };
}

sub units {
    my $self = shift;
    $self->{_units};
}

sub average_purchase_price {
    my $self = shift;
    $self->{_average_purchase_price};
}


1;
# ABSTRACT: Calculate inventory value/unit price (using LIFO/FIFO/weighted average)

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::Inventory::Valuation - Calculate inventory value/unit price (using LIFO/FIFO/weighted average)

=head1 VERSION

This document describes version 0.007 of Business::Inventory::Valuation (from Perl distribution Business-Inventory-Valuation), released on 2018-03-17.

=head1 SYNOPSIS

 use Business::Inventory::Valuation;

 my $biv = Business::Inventory::Valuation->new(
     method                   => 'LIFO', # required. choose LIFO/FIFO/weighted average
     #allow_negative_inventory => 0,     # optional, default 0
 );

 my @inv;

 # buy: 100 units @1500
 $biv->buy(100, 1500);
 @inv = $biv->inventory;              # => ([100, 1500])
 say $biv->units;                     # 100
 say $biv->average_purchase_price;    # 1500

 # buy more: 150 units @1600
 $biv->buy(150, 1600);
 @inv = $biv->inventory;              # => ([100, 1500], [150, 1600])
 say $biv->units;                     # 250
 say $biv->average_purchase_price;    # 1560

 # sell: 50 units @1700. with LIFO method, the most recently purchased units are sold first.
 $biv->sell( 50, 1700);               # returns two versions of realized profit & actual units sold: (7000, 5000, 50)
 @inv = $biv->inventory;              # => ([100, 1500], [100, 1600])
 say $biv->units;                     # 200
 say $biv->average_purchase_price;    # 1550

 # buy: 200 units @1500
 $biv->buy(200, 1500);
 @inv = $biv->inventory;              # => ([100, 1500], [100, 1600], [200, 1500])
 say $biv->units;                     # 400
 say $biv->average_purchase_price;    # 1550

 # sell: 350 units @1800
 $biv->sell(350, 1800);               # returns two versions of realized profit & actual units sold: (96250, 95000, 350)
 @inv = $biv->inventory;              # => ([50, 1500])
 say $biv->units;                     # 50
 say $biv->average_purchase_price;    # 1500
 ($units, $avgprice) = $biv->summary; # => (50, 1500)

 # sell: 60 units @1700
 $biv->sell(60, 1700);                # dies! tried to oversell more than available in inventory.

With FIFO method, the most anciently purchased units are sold first:

 my $biv = Business::Inventory::Valuation->new(method => 'FIFO');
 $biv->buy(100, 1500);
 $biv->buy(150, 1600);
 $biv->sell(50, 1700);                # returns two versions of realized profit & actual units sold: (7000, 10000, 50)
 @inv = $biv->inventory;              # => ([50, 1500], [150, 1600])
 say $biv->units;                     # 200
 say $biv->average_purchase_price;    # 1575

With C<weighted average> method, each purchase will be pooled into a single
group with purchase price set to average purchase price:

 my $biv = Business::Inventory::Valuation->new(method => 'weighted average');

 $biv->buy(100, 1500);
 @inv = $biv->inventory;              # => ([100, 1500])
 say $biv->units;                     # 100
 say $biv->average_purchase_price;    # 1500

 $biv->buy(150, 1600);
 @inv = $biv->inventory;              # => ([250, 1560])
 say $biv->units;                     # 250
 say $biv->average_purchase_price;    # 1560

 $biv->sell( 50, 1700);               # returns: (7000, 7000, 50)
 @inv = $biv->inventory;              # => ([200, 1560])
 say $biv->units;                     # 200
 say $biv->average_purchase_price;    # 1560

Overselling is allowed when C<allow_negative_inventory> is set to true. Amount
sold is set to the available inventory and inventory becomes empty:

 my $biv = Business::Inventory::Valuation->new(
     method => 'LIFO',
     allow_negative_inventory => 1,
 );
 $biv->buy(100, 1500);
 $biv->buy(150, 1600);
 $biv->sell(300, 1700);               # returns two versions of realized profit & actual units sold: (35000, 35000, 250)
 @inv = $biv->inventory;              # => ()
 say $biv->units;                     # 0
 say $biv->average_purchase_price;    # undef

=head1 DESCRIPTION

This class can be used if you want to calculate average purchase price from a
series of purchases each with different prices (like when buying stocks or
cryptocurrencies) or want to value your inventory using LIFO/FIFO method.

Keywords: average purchase price, inventory, inventory valuation, cost
accounting, FIFO, LIFO, weighted average, COGS, cost of goods sold.

=head1 METHODS

=head2 new

Usage: Business::Inventory::Valuation->new(%args) => obj

Known arguments (C<*> denotes required argument):

=over

=item * method* => str ("LIFO"|"FIFO"|"weighted average")

When the method is C<LIFO> or C<FIFO>, the class will keep track of each
purchase at different prices. Then when there is a selling, the units that are
most recently purchased (in the case of L<FIFO>) or most anciently purchased (in
the case of C<LIFO>) will be subtracted first.

When the method is C<weighted average>, each purchase will be mixed into a
single pool with the purchase price being calculated at average purchase price.

=item * allow_negative_inventory => bool (default: 0)

By default, when you try to C<sell()> more amount than you have bought, the
method will die. When this argument is set to true, the method will not die but
will simply ignore then excess amount sold (see L</"sell"> for more details).

=back

=head2 buy

Usage: $biv->buy($units, $unit_price) => num

Add units to inventory. Will return average purchase price, which is calculated
as the weighted average from all purchases.

=head2 sell

Usage: $biv->sell($units, $unit_price) => ($profit1, $profit2, $actual_units_sold)

Take units from inventory. If method is FIFO, will take the units according to
the order of purchase (units bought earlier will be taken first). If method is
LIFO, will take the units according to the reverse order of purchase (units
bought later will be taken first).

Will die if C<$units> exceeds the number of units in inventory (overselling),
unless when C<allow_negative_inventory> constructor argument is set to true (see
L</"new">) which will just take the inventory up to the amount of inventory and
set the inventory to zero.

C<$unit_price> is the unit selling price.

Will return a list containing two versions of realized profits as well actual
units sold. The first element is profit calculated using weighted average
method: (C<$unit_price> - I<average-purchase-price>) x I<units-sold>. The second
element is profit calculated by the actual purchase price of the taken units (in
the case of LIFO or FIFO). When method is `weighted average', the first element
and second element will be the same. Actual units sold can be different from
C<$units> if there is overselling, since we subtract only with the available
units in inventory.

To calculate the COGS (cost of goods sold), you can use:

 $units*$unit_price - $profit2

=head2 units

Usage: $biv->units => num

Return the current number of units in the inventory.

If you want to know each number of units bought at different prices, use
L</"inventory">.

=head2 average_purchase_price

Usage: $biv->average_purchase_price => num

Return the average purchase price, which is calculated by weighted average.

If there is no inventory, will return undef.

=head2 inventory

Usage: $biv->inventory => @ary

Return the current inventory, which is a list of C<[units, price]> arrays. For
example if you buy 500 units @10 then buy another 1000 units @12.5,
C<inventory()> will return: C<< ([500, 10], [1000, 12.5]) >>.

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
