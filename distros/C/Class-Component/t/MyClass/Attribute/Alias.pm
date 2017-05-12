package MyClass::Attribute::Alias;

use strict;
use warnings;
use base 'Class::Component::Attribute';

sub register {
    my($class, $plugin, $c, $method, $value) = @_;
    $c->register_method( $value => { plugin => $plugin, method => $method } );
}

1;
