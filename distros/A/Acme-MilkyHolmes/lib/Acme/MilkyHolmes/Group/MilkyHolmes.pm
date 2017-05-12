package Acme::MilkyHolmes::Group::MilkyHolmes;
use Mouse;
extends 'Acme::MilkyHolmes::Group::Detective';
with 'Acme::MilkyHolmes::Role::HasPersonalColor';

sub color_enable {
    my ($self) = shift;

    if ( @_ ) {
        $self->{color_enable} = $_[0];
    }
    else {
        if ( defined $self->{color_enable} ) {
            return $self->{color_enable}
        }
        if ( defined $self->common->[0]->{color_enable} ) {
            my $color_enable = $self->common->[0]->{color_enable} + 0;
            return $color_enable;
        }
    }
    return 1; #default is true
}


no Mouse;

1;
