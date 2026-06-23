package DBIONSTest::Rslt::B;

use warnings;
use strict;

use base qw/DBIO::Core/;
__PACKAGE__->table('b');
__PACKAGE__->add_columns('b');
1;
