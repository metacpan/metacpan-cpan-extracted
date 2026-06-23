package DBIONSTest::Result::D;

use warnings;
use strict;

use base qw/DBIO::Core/;
__PACKAGE__->table('d');
__PACKAGE__->add_columns('d');
1;
