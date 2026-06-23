package DBIONSTest::Rslt::A;

use warnings;
use strict;

use base qw/DBIO::Core/;
__PACKAGE__->table('a');
__PACKAGE__->add_columns('a');

# part of a test, do not remove
$_ = 'something completely utterly bogus';

1;
