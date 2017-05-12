
use strict;
use warnings;

package TColor;

use Class::Trait 'base';

use Class::Trait "TEquality";

our @REQUIRES = qw(getRGB setRGB);

sub getRed {
    my ($self) = @_;
    my ($red)  = $self->getRGB();
    return $red;
}

sub setRed {
    my ( $self, $red ) = @_;
    $self->setRGB( $red, undef, undef );
}

sub getGreen {
    my ($self) = @_;
    my ( undef, $green ) = $self->getRGB();
    return $green;
}

sub setGreen {
    my ( $self, $green ) = @_;
    $self->setRGB( undef, $green, undef );
}

sub getBlue {
    my ($self) = @_;
    my ( undef, undef, $blue ) = $self->getRGB();
    return $blue;
}

sub setBlue {
    my ( $self, $blue ) = @_;
    $self->setRGB( undef, undef, $blue );
}

sub equalTo {
    my ( $left, $right ) = @_;
    ( $left->isSameTypeAs($right) ) || die "cannot compare non-color objects";
    my @left = $left->getRGB();
    foreach my $i ( $right->getRGB() ) {
        if ( $i != shift @left ) {

            # return false
            return 0;
        }
    }

    # return true
    return 1;
}

1;

__DATA__
