package MyClass::Plugin::DefaultHook;

use strict;
use warnings;
use base 'Class::Component::Plugin';


sub default_hook :Hook {
    'defaulthook'
}

1;
