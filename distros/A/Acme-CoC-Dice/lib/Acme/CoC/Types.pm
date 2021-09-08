package Acme::CoC::Types;
use strict;
use warnings;
use utf8;

use Mouse::Util::TypeConstraints;

subtype 'command'
    => as 'Str'
    => where { $_ =~ /[Ss]kill|cc [1-9][0-9]*|ccb [1-9][0-9]*|[1-9][0-9]*[dD][1-9][0-9]*/ }
    => message { qw/$_ is invalid command/ };

1;
