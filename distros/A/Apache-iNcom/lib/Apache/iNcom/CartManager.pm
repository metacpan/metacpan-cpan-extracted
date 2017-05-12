#
#    CartManager.pm - Object that manages user shopping cart
#
#    This file is part of Apache::iNcom.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#
#    Copyright (C) 1999 Francis J. Lacoste, iNsu Innovations
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
package Apache::iNcom::CartManager;

use strict;


use vars qw( $VERSION );

BEGIN {
    ($VERSION) = '$Revision: 1.7 $' =~ /Revision: ([\d.]+)/;
}

=pod

=head1 NAME

Apache::iNcom::CartManager - Object responsible for managing the user
shopping cart. 

=head1 SYNOPSIS

    $Cart->order( \%item );
    my $items = $Cart->items;
    $Cart->empty;

=head1 DESCRIPTION

This is the part of the Apache::iNcom framework that is responsible for
managing the user shopping cart. It keep tracks of the ordered items and
is also responsible for the pricing of the order. It this is module that
computes taxes, discount, price, shipping, etc.

=head1 DESIGN RATIONALE

Well not completly since all these operations are delegated to user
implemented functions implemented in a pricing profile. The idea
behind it is to make policy external to the framework. One thing that
varies considerably between different applications is the pricing,
discount, taxes, etc. So this is left to the implementation of the
application programmer.

=head1 PRICING PROFILE

The pricing profile is a file which is C{eval}-ed at runtime. (It is also
reloaded whenever it changes on disk. It should return an hash reference
which may contains the following key :

=over

=item item_price

The function should return the price of the item. The function is passed
only one parameter : the item which we should compute the price.

    Ex:	item_price => sub {
	my $item = shift;
	my $data = $DB->template_get( "product", $item->{code} );
	return $data->{price};
    }

=item item_discount

The function should return the discounts that apply for that
particular item. It can return zero or more discounts. It returning
more that one discount return a an array reference. Discount are
substracted from the item price so don't return a percentage.

    Ex:	item_discount => sub {
	my $item = shift;

	# Discount are relative to item and quantity
	my $data = $DB->template_get( "discount", $item->{code},
				      $item->{quantity} );
	return unless $data; # No discount

	# Discount is proportional to the price
	return $item->{price} * $data->{discount};
    }

The subtotal of the cart is equal to the sum of

	($item->{price} - $item->{discount}) * $item->{quantity}

=item shipping

This function determines the shipping charges that will be added to
the subtotal. The function receives as arguments the subtotal of the
cart and an array ref to the cart's items. It should return zero or
more shipping charges that will be added to the subtotal. If returning
more that one charges, return an array reference.

    Ex: shipping => sub {
	    # Flat fee based shipping charges
	    if ( $Session{shipping} eq "ONE_NIGHT" ) {
		return 45;
	    } else {
		return 15;
	    }
	}

=item discount

That function determines discount that will be substracted from the
subtotal. Function is called with 3 arguments, the subtotal of the
cart, the shipping charges and an array reference to the cart's items.
Again the function may elect to return zero or more discounts and should
return an array reference if returning more that one discounts.

    Ex: discount => sub {
	my $subtotal = shift;
	my $user = $Request->user;
	return unless $user->{discount};

	return $subtotal * $user->{discount};
    }

=item taxes

That functions determines the taxes charges that will be added to the
order. It should return zero or more taxes. If the functions returns
more that one taxes, it should return an array reference. The
functions receives 4 arguments, the cart's subtotal, the shipping
charges, the discount and the cart's items as an array reference.

    Ex: taxes => sub {
	my ( $sub, $ship, $disc ) = @_;

	# We only charges taxes to Quebec's resident. All our
	# items are taxable and is shipping.
	if ( ${$Request->user}->{province} eq "QC" ) {
	    my $taxable = $sub + $ship - $disc;
	    my $gst = $taxable * 0.07
	    my $gsp = ($taxable + $gst) * 0.075

	    return [ $gst, $gsp ];
	} else {
	    return undef;
	}
    }

=back

If one of these functions is left undefined. The framework will create
one on the fly which will return 0. (No taxes, no discount, no
shipping charges, item is free, etc).

All those functions are defined and execute in the namespace of the
pages which will use the $Cart object. This means that those functions
have access to the standard Apache::iNcom globals ($Request, %Session, 
$Localizer, $Locale, etc ). DONT ABUSE IT. Also, don't call any methods
on the $Cart object or you'll die of infinite recursion.

=head1 WHAT IS AN ITEM

An item is simply an hash with some reserved key names. All other keys
are ignored by the CartManager. Each item with the same (non reserved)
key values is assumed to be identic in terms of price, discount, etc.

This design was chosen to handle the infinite variety of item
attributes (color, size, variant, ...). The framework doesn't need
knowledge of those, only the application specific part. (The pricing
functions.)

These are reserved names and can't be used as item attributes :
C<quantity>, C<price>, C<discount>, C<subtotal>

=head1 INITIALIZATION

An object is automatically initialized on each request by the
Apache::iNcom framework. It is accessible through the $Cart global
variable in Apache::iNcom pages.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my ( $cart, $package, $profile_file ) = @_;

    $cart ||= {};

    bless { profile_file => $profile_file,
	    cart	 => $cart,
	    package	 => $package,
	  }, $class;
}

sub cart {
    my $self = shift;

    # Return the cart data structure.
    $self->{cart};
}

my %DEFAULT_DELEGATES = (
			 item_price	=> sub { 0 },
			 item_discount	=> sub { 0 },
			 discount	=> sub { 0 },
			 shipping	=> sub { 0 },
			 taxes		=> sub { 0 },
			);

sub load_delegates {
    my $self = shift;

    # Define delegates in the namespace of the page
    my $delegates_code = "package " . $self->{package} . ";\n";

    # Read in the delegates code
    open ( DELEGATES, $self->{profile_file} )
      or die "Error loading pricing delegates: $!\n";
    my $line;
    while ( defined ( $line = <DELEGATES> ) ) {
	$delegates_code .= $line;
    }
    close DELEGATES;

    my $delegates = eval $delegates_code;
    die "Error evaluating delegates: $@" if $@;
    die "Delegates didn't evaluate to an hash ref\n"
      unless ref $delegates eq "HASH";

    # Make sure that defaults functions are defined for
    # all of them
    for my $name (keys %DEFAULT_DELEGATES ) {
	my $f = $delegates->{$name} ||= $DEFAULT_DELEGATES{$name};
	die "Delegate $name is not a function ref\n" 
	  unless ref $f eq "CODE";
    }

    $delegates;
}

my %RESERVED_ITEM_NAMES = map { $_ => 1 }
  qw( quantity price discount subtotal );

=pod

=head1 METHODS

=head2 order ( \%item, ... )

This method will add all the specified items (hash reference) to the
Cart. The quantity ordered should be specified in the C<quantity>
attribute. (If unspecified, it is assumed to be one). If an identical
item is already in the cart, the quantity will be added.

Use a negative quantity to remove from the quantity ordered. If the
new quantity is lower or equal to zero it will be removed.

Use a quantity of 0 to remove an item.

=cut

sub order {
    my $self = shift;

    # Add items to shopping cart
    for my $item (@_) {
	my @attr = sort grep { not $RESERVED_ITEM_NAMES{$_} } keys %$item;

	my $key = join "\0", map { $item->{$_} } @attr;

	if ( defined $item->{quantity} && $item->{quantity} == 0 ) {
	    delete $self->{cart}{items}{$key}
	} else {
	    my $q = $item->{quantity} || 1;
	    my $cart_item = $self->{cart}{items}{$key};
	    unless ( $cart_item ) {
		# Item is not already in cart
		$self->{cart}{items}{$key} = $cart_item = {};
		# Copy key attributes
		for my $attr ( @attr ) {
		    $cart_item->{$attr} =  $item->{$attr};
		}
		$cart_item->{quantity} = 0;
	    }
	    $cart_item->{quantity} += $q;

	    # Toss item if deleted
	    delete $self->{cart}{items}{$key}
	      if ($cart_item->{quantity} <= 0);
	}

	# Mark cart as needing recomputation
	$self->{cart}{dirty} = 1;
    }
}

=pod

=head2 empty

Removes all items from the cart.

=cut

sub empty {
    my $self = shift;

    delete $self->{cart}{items};
    $self->{cart}{items}    = {};

    # Reset cart status
    $self->{cart}{subtotal} = 0;
    $self->{cart}{discount} = 0;
    $self->{cart}{dirty}    = 0;
    $self->{cart}{total}    = 0;
    $self->{cart}{taxes}    = 0;
    $self->{cart}{shipping} = 0;
}

=pod

=head2 is_empty

Return true if no items are in the cart.

=cut

sub is_empty {
    my $self = shift;

    return keys %{$self->{cart}{items}} == 0;
}

=pod

=head2 items

Return all the ordered items as an array. Each item have the following
attribute set :

=over

=item quantity

The quantity of the item ordered.

=item price

The price of that item.

=item discount

The discounts applied to this item.

=item subtotal

That item subtotal.

=back

=cut

sub items {
    my $self = shift;

    $self->compute;

    return values %{$self->{cart}{items}};
}

=pod

=head2 subtotal

Returns the cart subtotal. (This is before global discount, shipping
charges and taxes.)

=cut

sub subtotal {
    my $self = shift;

    $self->compute;
    return $self->{cart}{subtotal};
}

=pod

=head2 taxes

Returns the taxes that will be added to the order.

=cut

sub taxes  {
    my $self = shift;

    $self->compute;
    my $taxes = $self->{cart}{taxes};

    return wantarray ? @$taxes : $taxes if ref $taxes;
    return $taxes;
}

=pod

=head2 total

Returns the order total. (subtotal + shipping charges - discounts + taxes ).

=cut

sub total {
    my $self = shift;

    $self->compute;
    return $self->{cart}{total};
}

=pod

=head2 discount

Returns the overall discount that applied to this order.

=cut

sub discount {
    my $self = shift;

    $self->compute;
    my $discount = $self->{cart}{discount};

    return wantarray ? @$discount : $discount if ref $discount;
    return $discount;
}

=pod

=head2 shipping

Returns the shipping charges for this order.

=cut

sub shipping {
    my $self = shift;

    $self->compute;
    my $shipping = $self->{cart}{shipping};

    return wantarray ? @$shipping : $shipping if ref $shipping;
    return $shipping;
}

=pod

=head2 item_price ( \%item )

Returns the price of the item specified. If no quantity is specified,
a quantity of 1 is assumed. This method doesn't modify the cart.

=cut

sub item_price {
    my ($self, $item) = @_;

    # Load the customized function to calculate price
    my $delegates = $self->load_delegates;

    my $item_copy = { %$item };
    $item_copy->{quantity} ||= 1;

    return $delegates->{item_price}->( $item_copy );
}

=pod

=head2 item_discount ( \%item )

Returns the discounts associated with the specified item. It no
quantity is specified, a quantity of 1 is assumed. This method doesn't
modify the cart.

=cut

sub item_discount {
    my ($self, $item) = @_;

    # Load the customized function to calculate price
    my $delegates = $self->load_delegates;

    my $item_copy = { %$item };
    $item_copy->{quantity} ||= 1;
    $item_copy->{price} = $delegates->{item_price}->( $item_copy );

    return $delegates->{item_discount}->( $item_copy );
}

=pod

=head2 item_pricing ( \%item )

Returns the item as it would be added to the cart. C<quantity>,
C<price>, C<discount> and C<subtotal> will be set in the returned
item. This method doesn't modify the cart.

=cut

sub item_pricing {
    my ($self, $item) = @_;

    # Load the customized function to calculate price
    my $delegates = $self->load_delegates;

    # Copy the item infos
    my $item_pricing = { %$item };

    $item_pricing->{quantity} ||= 1;

    my $item_price	= $delegates->{item_price}->( $item_pricing );
    my $item_discount   = $delegates->{item_discount}->( $item_pricing );

    $item_pricing->{price}	= $item_price;
    $item_pricing->{discount}	= $item_discount;
    $item_price			= apply_discount( $item_price, $item_discount);
    $item_pricing->{subtotal}	= $item_price * $item->{quantity};

    return $item_pricing;
}

sub compute {
    my $self = shift;

    return unless $self->{cart}{dirty};

    # Load the customized function to calculate price
    my $delegates = $self->load_delegates;

    my $subtotal = 0;
    my $items = [values %{$self->{cart}{items} }];
    for my $item ( @$items ) {
	my $item_price	    = $delegates->{item_price}->( $item );
	my $item_discount   = $delegates->{item_discount}->( $item );

	$item->{price}	    = $item_price;
	$item->{discount}   = $item_discount;
	$item_price	    = apply_discount( $item_price, $item_discount);
	$item->{subtotal}   = $item_price * $item->{quantity};
	$subtotal += $item->{subtotal};
    }

    $self->{cart}{subtotal} = $subtotal;
    my $shipping    = $self->{cart}{shipping} =
      $delegates->{shipping}->( $subtotal, $items );
    my $discount    = $self->{cart}{discount} =
      $delegates->{discount}->( $subtotal, $shipping, $items );
    my $taxes	    = $self->{cart}{taxes}    =
      $delegates->{taxes}->( $subtotal, $shipping, $discount, $items);

    my $total = $subtotal;

    # Add order discounts
    $total = apply_discount( $total, $discount );

    # Add shippings
    $total = apply_charges( $total, $shipping );

    # Add taxes
    $total = apply_charges( $total, $taxes );

    $self->{cart}{total}    = $total;

    $self->{cart}{dirty}    = 0;
}

sub apply_charges {
    my ( $amount, $charges ) = @_;

    if ( ref $charges ) {
	foreach my $c ( @$charges ) {
	    $amount += $c;
	}
    } else {
	$amount += $charges;
    }

    $amount;
}

sub apply_discount {
    my ($amount, $discount) = @_;

    if ( ref $discount ) {
	foreach my $d ( @$discount ) {
	    $amount -= $discount;
	}
    } else {
	$amount -= $discount;
    }

    $amount;
}

1;

__END__

=pod

=head1 AUTHOR

Copyright (c) 1999 Francis J. Lacoste and iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 SEE ALSO

Apache::iNcom(3) Apache::iNcom::Request(3) Apache::iNcom::OrderManager(3)

=cut
