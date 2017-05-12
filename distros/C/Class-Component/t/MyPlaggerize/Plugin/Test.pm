package MyPlaggerize::Plugin::Test;
use strict;
use warnings;
use base 'Class::Component::Plugin';

sub feed : Hook('feed') {
    my($self, $c) = @_;
    $self->config->{config}->{return};
}

1;
