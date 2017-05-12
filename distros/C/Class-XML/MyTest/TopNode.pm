package MyTest::TopNode;

use strict;

use base qw/Class::XML/;

__PACKAGE__->has_child('bar' => 'MyTest::SingleChild');
__PACKAGE__->has_children('stalk' => 'MyTest::MultiChild');
__PACKAGE__->has_relation(four_beans =>
                           [ './child::*[@beans=4]' => 'MyTest::MultiChild' ]);
__PACKAGE__->has_relation(n_beans =>
                           [ './child::*[@beans=%i]' => 'MyTest::MultiChild' ]);

1;
