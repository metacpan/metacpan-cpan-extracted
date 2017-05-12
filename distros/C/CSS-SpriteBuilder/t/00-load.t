
use strict;
use warnings;
use lib qw(lib);

use Test::More tests => 1;

BEGIN { use_ok('CSS::SpriteBuilder') };

diag( "Testing CSS::SpriteBuilder $CSS::SpriteBuilder::VERSION, Perl $], $^X" );
