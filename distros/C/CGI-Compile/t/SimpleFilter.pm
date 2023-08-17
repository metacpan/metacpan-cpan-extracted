package SimpleFilter;
use strict;
use warnings;
use Filter::Util::Call;

sub import {
    filter_add([]);
}

sub filter {
    my $self = shift;
    my $status = filter_read();

    s{\btnirp\b}{print}g;

    return $status;
}

1;
