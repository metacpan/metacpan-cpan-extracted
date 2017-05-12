package MyTest::SingleChild;

use strict;

use base qw/Class::XML/;

__PACKAGE__->has_parent('foo' => 'MyTest::TopNode');
__PACKAGE__->has_attribute('counter');

1;
