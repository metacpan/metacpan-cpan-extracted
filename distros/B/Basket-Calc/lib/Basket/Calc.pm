package Basket::Calc;

use 5.010001;
use Mouse;
use experimental 'smartmatch';

# ABSTRACT: Basket/Cart calculation library with support for currency conversion, discounts and tax

our $VERSION = '0.5'; # VERSION

use Scalar::Util qw(looks_like_number);
use Finance::Currency::Convert::Yahoo;
use Carp;


has 'debug' => (
    is      => 'rw',
    isa     => 'Bool',
    trigger => \&_set_debug,
    lazy    => 1,
    default => sub { 0 },
);

has 'items' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    clearer => 'empty_items',
);

has 'discount' => (
    is      => 'rw',
    isa     => 'HashRef',
    clearer => 'no_discount',
);


has 'currency' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);


has 'tax' => (
    is      => 'rw',
    isa     => 'Num',
    lazy    => 1,
    default => sub { 0 },
);


sub add_item {
    my ($self, $item) = @_;

    # make sure the input is sane
    unless (ref $item eq 'HASH') {
        carp "parameter has to be a HASHREF";
        return;
    }

    foreach my $key ('price') {
        unless (exists $item->{$key} and $item->{$key}) {
            carp "$key missing";
            return;
        }
    }

    unless (looks_like_number($item->{price})) {
        carp "'price' is not a number";
        return;
    }

    # calculate amount from quantity and price
    if (exists $item->{quantity}) {
        if (!looks_like_number($item->{quantity}) || ($item->{quantity} < 0)) {
            carp "'quantity' is not a number or smaller than 0";
            return;
        }

        $item->{amount} = $item->{price} * $item->{quantity};
    }
    else {
        $item->{amount}   = $item->{price};
        $item->{quantity} = 1;
    }

    $item->{currency} = $self->currency
        unless (exists $item->{currency} and $item->{currency});

    # convert currency if needed
    if ($item->{currency} ne $self->currency) {
        my $amount =
            Finance::Currency::Convert::Yahoo::convert($item->{amount},
            $item->{currency}, $self->currency);

        unless ($amount) {
            carp "could not get "
                . $item->{amount} . " "
                . $item->{currency}
                . " converted to "
                . $self->currency;
            return;
        }

        $item->{orig_amount}   = $item->{amount};
        $item->{orig_currency} = $item->{currency};

        $item->{amount}   = $amount;
        $item->{currency} = $self->currency;
    }

    print __PACKAGE__ . ' added item: ' . join(' ', %$item) . $/
        if $self->debug;

    $self->items([ @{ $self->items || [] }, $item ]);

    return $item;
}


sub add_discount {
    my ($self, $discount) = @_;

    # make sure the input is sane
    unless (ref $discount eq 'HASH') {
        carp "parameter has to be a HASHREF";
        return;
    }

    foreach my $key ('type', 'value') {
        unless (exists $discount->{$key} and $discount->{$key}) {
            carp "'$key' missing";
            return;
        }
    }

    unless ($discount->{type} =~ m/^(percent|amount)$/x) {
        carp "'type' has to be either percent, or amount";
        return;
    }

    unless (looks_like_number($discount->{value})) {
        carp "'value' is not a number";
        return;
    }

    given ($discount->{type}) {
        when ('percent') {
            if ($discount->{value} <= 0 or $discount->{value} > 1) {
                carp "'percent' has to be a decimal between 0 and 1";
                return;
            }
        }
        when ('amount') {
            $discount->{currency} = $self->currency
                unless exists $discount->{currency};

            # convert currency if needed
            if ($discount->{currency} ne $self->currency) {
                my $amount = Finance::Currency::Convert::Yahoo::convert(
                    $discount->{value}, $discount->{currency}, $self->currency);

                unless ($amount) {
                    carp "could not get "
                        . $discount->{value} . " "
                        . $discount->{currency}
                        . " converted to "
                        . $self->currency;
                    return;
                }

                $discount->{orig_value}    = $discount->{value};
                $discount->{orig_currency} = $discount->{currency};

                $discount->{value}    = $amount;
                $discount->{currency} = $self->currency;
            }
        }
    }

    print __PACKAGE__ . ' added discount: ' . join(' ', %$discount) . $/
        if $self->debug;

    $self->discount($discount);

    return $self->discount;
}


sub calculate {
    my ($self) = @_;

    unless ($self->items) {
        carp "no items added";
        return;
    }

    my $total = {
        value      => 0,
        net        => 0,
        tax_amount => 0,
        discount   => 0,
    };

    print __PACKAGE__ . " -- calculating totals --\n" if $self->debug;

    # calculate net
    foreach my $item (@{ $self->items }) {
        print __PACKAGE__ . ' item: ' . join(' ', %$item) . $/ if $self->debug;

        $total->{net} += $item->{amount};
    }

    my $original_net = $total->{net};

    # apply discounts
    if ($self->discount) {
        print __PACKAGE__ . ' discount: ' . join(' ', %{ $self->discount }) . $/
            if $self->debug;

        given ($self->discount->{type}) {
            when ('percent') {
                $total->{net} *= (1 - $self->discount->{value});
            }
            when ('amount') {
                $total->{net} = $total->{net} - $self->discount->{value};
                $total->{net} = 0 if $total->{net} < 0;
            }
        }
    }

    # calculate tax
    $total->{tax_amount} = $total->{net} * $self->tax;
    $total->{value}      = $total->{net} + $total->{tax_amount};
    $total->{discount}   = $original_net - $total->{net};

    # proper rounding and formatting
    $total->{$_} = _round($total->{$_}) for keys %$total;

    # remind what the currency is that was requested
    $total->{currency} = $self->currency;

    print __PACKAGE__ . ' total: ' . join(' ', %$total) . $/ if $self->debug;

    $self->empty_items;
    $self->no_discount;

    return $total;
}

sub _set_debug {
    my ($self, $value, $some) = @_;

    $Finance::Currency::Convert::Yahoo::CHAT = $value;

    return;
}

sub _round {
    my ($float) = @_;

    # some stupid perl versions on some platforms can't round correctly and i
    # don't want to use more modules
    $float += 0.001 if ($float =~ m/\.[0-9]{2}5/);

    return sprintf('%.2f', sprintf('%.10f', $float)) + 0;
}


1;    # End of Basket::Calc

__END__

=pod

=head1 NAME

Basket::Calc - Basket/Cart calculation library with support for currency conversion, discounts and tax

=head1 VERSION

version 0.5

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Basket::Calc;
    use Data::Dump 'dump';

    my $basket = Basket::Calc->new(debug => 1, currency => 'NZD', tax => .15);
    $basket->add_item({ price => 14.90, currency => 'USD', quantity => 2 });
    $basket->add_item({ price => 59, currency => 'EUR'});
    $basket->add_item({ price => 119.15, currency => 'JPY' });
    
    $basket->add_discount({ type => 'percent', value => .2 });
    # or
    $basket->add_discount({ type => 'amount', value => 15, currency => 'HKD' });
    
    print dump $basket->calculate;

=head1 ATTRIBUTES

=head2 debug

=head2 currency

=head2 tax

=head1 SUBROUTINES/METHODS

=head2 add_item

=head2 add_discount

=head2 calculate

=head1 BUGS

Please report any bugs or feature requests on GitHub's issue tracker L<https://github.com/nupfel/Basket-Calc/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Basket::Calc

You can also look for information at:

=over 4

=item * GitHub repository

L<https://github.com/nupfel/Basket-Calc>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Basket-Calc>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Basket-Calc>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Lenz Gschwendtner (@norbu09), for being an awesome mentor and friend.

=back

=head1 AUTHOR

Tobias Kirschstein <lev@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Tobias Kirschstein.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
