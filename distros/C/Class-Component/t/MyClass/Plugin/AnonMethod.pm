package MyClass::Plugin::AnonMethod;

use strict;
use warnings;
use base 'Class::Component::Plugin';

sub foo :Anon(sub {'anonmethod'}) {};

1;
