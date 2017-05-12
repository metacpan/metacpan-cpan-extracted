package MapperExample::ShoppingCart;
use strict;
use warnings;
use Carp qw(croak);

sub new {
    my $class = shift;
    my $attr = shift;
    my $self = bless { id => undef, items => [] }, $class;
    $self->{id} = $attr->{id} if $attr->{id};
    if( $attr->{items} ) {
        $self->add_item($_) for @{$attr->{items}};
    }
    $self->{created} = $attr->{created} if $attr->{created};
    return $self;
}

sub items {
    my $self = shift;
    $self->{items} = shift if @_;
    return $self->{items};
}

sub created {
    my $self = shift;
    $self->{created} = shift if @_;
    return $self->{created};
}

sub id {
    my $self = shift;
    $self->{id} = shift if @_;
    return $self->{id};
}

sub add_item {
    my $self = shift;

    for my $prod ( @_ ) {
        unless( $prod and ref($prod) eq 'MapperExample::Product' ) {
            croak 'invalid data :' . $prod ;
        }
        $self->_add($prod);
    }

    return scalar(@{$self->items});
}

sub _add {
    my ( $self, $prod ) = @_;
    push @{$self->items}, $prod;
}

sub remove_item {
    my $self = shift;

    $self->_remove($_) for @_;
    return scalar(@{$self->items});
}

sub _remove {
    my ( $self, $key ) = @_;

    for my $i ( reverse ( 0 .. $#{$self->items} ) ) {
        if( $self->items->[$i]->prodkey eq $key ) {
            splice(@{$self->items}, $i, 1);
            return;
        }
    }
}

sub total_price {
    my $self = shift;
    return $self->product_total_price + $self->shipping_charge;
}

sub product_total_price {
    my $self = shift;
    my $price = 0;
    $price += $_->price for @{$self->items};
    return $price;
}

sub shipping_charge {
    my $self = shift;

    if( $self->product_total_price >= 2000 ) {
        return 0;
    }
    else {
        return BASIC_SHIPPING_CHARGE();
    }
}

sub BASIC_SHIPPING_CHARGE { 100 }

sub item_num {
    my $self = shift;
    return scalar(@{$self->items});
}


1;
