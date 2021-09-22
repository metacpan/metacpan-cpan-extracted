use strict;
use Test::More 0.98;
use lib '../lib';
use App::dumpbin;
use Path::Tiny;
use Config;
#
if ( $Config::Config{ivsize} < 8 ) {
    plan skip_all => 'No point testing 64bit math on a 32bit system.';
}
else {
    #
    my %exports = App::dumpbin::exports(
        Path::Tiny->new(__FILE__)->absolute->parent->child( 'bin', 'hello-world-x64.dll' ) );
    is $exports{name}, 'hello-world.dll', 'name is correct';

    # 0x180001030
    is $exports{exports}{'DllMain'}[0], 6442455088, '[DllMain] address is correct';
    is $exports{exports}{'DllMain'}[1], 1,          '[DllMain] ordinal is correct';

    # 0x180001000
    is $exports{exports}{'MessageBoxThread'}[0], 6442455040,
        '[MessageBoxThread] address is correct';
    is $exports{exports}{'MessageBoxThread'}[1], 2, '[MessageBoxThread] ordinal is correct';
    #
    done_testing;
}
