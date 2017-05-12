package MyTest::MultiChild;

use strict;

use base qw/Class::XML/;

__PACKAGE__->element_name('stalk');
__PACKAGE__->has_parent('foo' => 'MyTest::TopNode');
__PACKAGE__->has_attribute('beans');

1;
