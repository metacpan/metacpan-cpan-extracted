use 5.010000;
use strict;
use warnings;
use Test::More tests => 2;


my $file = 'bin/getvideo';


ok( -e $file, "File $file found" );


my $message = `$^X -c $file 2>&1`;

like( $message, qr/syntax OK/i, "$file compiles" );


done_testing();
