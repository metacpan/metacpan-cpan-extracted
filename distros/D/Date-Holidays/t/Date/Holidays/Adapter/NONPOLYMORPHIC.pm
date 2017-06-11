package Date::Holidays::Adapter::NONPOLYMORPHIC;

use strict;
use warnings;

use base 'Date::Holidays::Adapter';

sub holidays {
    my ($self, %params) = @_;

    my $dh = $self->{'_adaptee'}->new();

    if ($dh) {
        return $dh->nonpolymorphic_holidays(year => $params{'year'});
    } else {
        return;
    }
}

sub is_holiday {
    my ($self, %params) = @_;

    my $dh = $self->{'_adaptee'}->new();

    if ($dh) {
        return $dh->is_nonpolymorphic_holiday(year => $params{'year'}, month => $params{'month'}, day => $params{'day'});
    } else {
        return;
    }
}