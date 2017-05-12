#!perl -T

use strict;
use warnings;
use Test::More;

use App::KGB;
my $app_kgb_version = $App::KGB::VERSION;

my $kgb_bot_version;
my $f;
open( $f, "script/kgb-bot" );
while ( defined( $_ = <$f> ) ) {
    chomp;

    if ( /^our \$VERSION = '(.+)';$/ ) {
        $kgb_bot_version = $1;
        last;
    }
}

ok( $app_kgb_version eq $kgb_bot_version,
    "App::KGB version ($app_kgb_version) matches kgb-bot version ($kgb_bot_version)"
);

done_testing();
