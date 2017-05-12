package MyClass::Plugin::AliasMethod;

use strict;
use warnings;
use base 'Class::Component::Plugin';

sub foo :Alias('bar') { 'baz' };

1;
