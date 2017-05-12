use strict;
use warnings;

use lib 't/lib';
use T::RequireDateTime;

use Test::More;
use Test::Fatal;

{
    like(
        exception {
            DateTime::TimeZone->new(
                name => 'America/Chicago; print "hello, world\n";' );
        },
        qr/invalid name/,
        'make sure potentially malicious code cannot sneak into eval'
    );
}

{
    like(
        exception { DateTime::TimeZone->new( name => 'Bad/Name' ) },
        qr/invalid name/,
        'make sure bad names are reported'
    );
}

done_testing();
