use strict;
use Test::More 0.98;
use lib '../lib';
use App::dumpbin;
use Path::Tiny;
#
my %exports = App::dumpbin::exports(
    Path::Tiny->new(__FILE__)->absolute->parent->child( 'bin', 'hello-world-x86.dll' ) );
#
is $exports{name}, 'hello-world.dll', 'name is correct';
#
is $exports{exports}{'_DllMain@12'}[0], 0x10001020, '[DllMain] address is correct';
is $exports{exports}{'_DllMain@12'}[1], 1,          '[DllMain] ordinal is correct';
#
is $exports{exports}{'_MessageBoxThread@4'}[0], 0x10001000, '[MessageBoxThread] address is correct';
is $exports{exports}{'_MessageBoxThread@4'}[1], 2,          '[MessageBoxThread] ordinal is correct';
#
done_testing;
