package Date::Holidays::Adapter::Nonpolymorphic;

use strict;
use warnings;

use base 'Date::Holidays::Adapter';

sub holidays {
    my ($self, %params) = @_;

    my $dh = $self->{'_adaptee'}->new();

    if ($dh) {
        return $dh->nonpolymorphic_holidays($params{'year'});
    } else {
        return;
    }
}

sub is_holiday {
    my ($self, %params) = @_;

    my $dh = $self->{'_adaptee'}->new();

    if ($dh) {
        return $dh->is_nonpolymorphic_holiday($params{'year'}, $params{'month'}, $params{'day'});
    } else {
        return;
    }
}

1;
