package MyClass::Plugin::AliasMethod2;

use strict;
use warnings;
use base 'Class::Component::Plugin';

sub foo :Method('bar') { 'baz' };

1;
