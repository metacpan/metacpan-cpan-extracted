use strict;
use warnings;

use File::Spec;
use Test::More;
use DateTimeX::Lite::TimeZone;

use lib File::Spec->catdir( File::Spec->curdir, 't' );


plan tests => 1;

{
    my $tz = eval { DateTimeX::Lite::TimeZone->load( name => 'America/Chicago; print "hello, world\n";' ) };
    like( $@, qr/invalid name/, 'make sure potentially malicious code cannot sneak into eval' );
}
