package MyClass::Plugin::Attribute;

use strict;
use warnings;
use base 'Class::Component::Plugin';

sub test :Method :Test {
    my($self, $c, $str) = @_;
    $c->{test_str} = $str;
    'test'
}

1;
