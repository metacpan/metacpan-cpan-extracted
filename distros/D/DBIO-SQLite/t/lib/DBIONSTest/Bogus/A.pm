package DBIONSTest::Bogus::A;

use warnings;
use strict;

use base qw/DBIO::Core/;
__PACKAGE__->table('a');
__PACKAGE__->add_columns('a');
1;
