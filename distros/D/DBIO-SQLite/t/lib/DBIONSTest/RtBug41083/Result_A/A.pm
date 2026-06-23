package DBIONSTest::RtBug41083::Result_A::A;
use strict;
use warnings;
use base 'DBIO::Core';
__PACKAGE__->table('a');
__PACKAGE__->add_columns('a');
1;
