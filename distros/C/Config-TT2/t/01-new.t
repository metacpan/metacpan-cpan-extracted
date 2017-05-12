#!perl -T

use Test::More;
use Try::Tiny;

use_ok('Config::TT2');

foreach my $opt (
    qw/
    PRE_PROCESS
    PROCESS
    POST_PROCESS
    WRAPPER
    AUTO_RESET
    DEFAULT
    OUTPUT
    OUTPUT_PATH
    ERROR
    ERRORS
    /
  )
{
    my $error;
    try {
        Config::TT2->new( $opt => 0 );
    }
    catch { $error = $_ };
    like( $error, qr/$opt/i, "unsupported option $opt" );
}

{
    my $error;
    my $opt = { DEBUG => 'foo' };
    try {
        Config::TT2->new( $opt );
    }
    catch { $error = $_ };
    like( $error, qr/unknown debug flag/i, "unknown debug flag" );
}

done_testing(12);

