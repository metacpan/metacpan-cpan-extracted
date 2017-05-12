package MyTest::HasAttrs;

use strict;

use base qw/Class::XML/;

__PACKAGE__->has_attributes(qw/length colour/);
__PACKAGE__->has_attribute('flavour');

1;
