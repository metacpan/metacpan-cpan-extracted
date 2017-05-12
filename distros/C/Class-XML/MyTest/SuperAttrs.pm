package MyTest::SuperAttrs;

use strict;

use base qw/MyTest::HasAttrs/;

__PACKAGE__->has_attribute('bongo');

1;
