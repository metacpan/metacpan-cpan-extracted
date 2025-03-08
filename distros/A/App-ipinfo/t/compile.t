use warnings;

use Test::More 1.0;

my $file = 'blib/script/ipinfo';

use_ok( 'App::ipinfo' );

my $output = `$^X -Mblib -c $file 2>&1`;

like( $output, qr/syntax OK$/, 'script compiles' );

done_testing();
