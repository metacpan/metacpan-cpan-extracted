#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

eval 'use Test::MockModule';
plan skip_all => 'Test::MockModule required' if $@;

plan tests => 15;

require Crypt::GpgME;

my $called = 0;
my $version = 'junk';

my $gpgme = Test::MockModule->new('Crypt::GpgME');
$gpgme->mock(check_version => sub ($;$) {
        ++$called;
        $version = $_[1];
});

lives_ok (sub {
        Crypt::GpgME->import;
}, 'import without arguments');

is ($called, 1, 'import without arguments called check_version');
is ($version, undef, 'import without arguments called check_version with undef');

lives_ok (sub {
        Crypt::GpgME->import('-no-init');
}, 'import with -no-init');

is ($called, 1, 'import with -no-init didn\'t call check_version');

throws_ok (sub {
        Crypt::GpgME->import('-init');
}, qr/requires a version number/, 'import with -init');

is ($called, 1, 'import with -init didn\'t call check_version');

lives_ok (sub {
        Crypt::GpgME->import(-init => '1');
}, 'import with -init and version number');

is ($called, 2, 'import with -init and version number called check_version');
is ($version, '1', 'check_version called with right version number');

lives_ok (sub {
        Crypt::GpgME->import($Crypt::GpgME::VERSION);
}, 'import with version number');

is ($called, 3, 'import with version number called check_version');
is ($version, undef, 'import with version number called check_version with undef');

throws_ok (sub {
        Crypt::GpgME->import('10.0');
}, qr/version 10\.0 required--this is only version/, 'import with future version number');

is ($called, 3, 'import with future version number didn\'t call check_version');
