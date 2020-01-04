use strict;
use warnings;

use Test::More 1.0;

my $file = 'blib/script/url';

use_ok( 'App::url' );

my $output = `$^X -Mblib -c $file 2>&1`;

like( $output, qr/syntax OK$/, 'script compiles' );

done_testing();
