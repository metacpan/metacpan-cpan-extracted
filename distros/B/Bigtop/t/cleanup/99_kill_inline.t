use strict;

use Test::More tests => 1;

use lib 't';
use Purge;

Purge::real_purge_dir( '_Inline' );

ok( ( not -d '_Inline' ), 'house cleaned' );
