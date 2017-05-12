package MapperExample::Product;
use strict;
use warnings;
use Carp qw(croak);

sub new {
    my $class = shift;

    my $self = bless +{}, $class;

    my %attr;
    if ( ref( $_[0] ) eq 'HASH' ) {
        %attr = %{ $_[0] };
    }
    elsif ( @_ % 2 == 0 ) {
        %attr = @_;
    }
    else {
        croak "パラメータはHash ReferenceかHashの必要があります";
    }

    $self->prodkey( delete $attr{prodkey} ) if exists $attr{prodkey};
    $self->title( delete $attr{title} )     if exists $attr{title};
    $self->price( delete $attr{price} )     if exists $attr{price};

    # 残りの不要な属性は無視される

    return $self;
}

sub prodkey {
    my $self = shift;

    if( defined $_[0] ) {
        my $prodkey = shift;
        croak "型番の形式がちがいます" unless $prodkey =~ /^[A-Z0-9]+-\w+$/;
        $self->{prodkey} = $prodkey;
    }

    return $self->{prodkey};
}

sub title {
    my $self = shift;

    if( defined $_[0] ) {
        $self->{title} = shift;
    }

    return $self->{title};
}

sub price {
    my $self = shift;

    if( defined $_[0] ) {
        my $price = shift;
        croak "priceはintで設定してください" unless $price =~ /^\d+$/;
        $self->{price} = $price;
    }

    return $self->{price};
}

1;
