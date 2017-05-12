package CLIDTest::Single;

use strict;
use warnings;
use base qw( CLI::Dispatch );

sub get_command { 'DumpMe' }

1;
