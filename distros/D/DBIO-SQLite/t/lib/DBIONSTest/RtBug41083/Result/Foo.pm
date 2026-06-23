package DBIONSTest::RtBug41083::Result::Foo;
use strict;
use warnings;
use base 'DBIO::Core';
__PACKAGE__->table('foo');
__PACKAGE__->add_columns('foo');
1;
