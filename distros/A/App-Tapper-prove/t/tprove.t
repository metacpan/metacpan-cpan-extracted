use Test::More;
use Test::Deep;
use Test::MockModule;

use strict;
use warnings;

my $MOCK_TMPDIR = sub { "MOCKED-TEMPDIR" };

my $module = Test::MockModule->new('File::Temp');
$module->mock("tempdir", $MOCK_TMPDIR);
ok($module->is_mocked("tempdir"), "mocked tempdir");

require 'bin/tprove'; # after mock!

like(get_prove(),
     qr,^/.*/prove$,,
     "get_prove");

cmp_deeply([patch_args(qw( FOO BAR -a ARCHIVE BAZ AFFE -a ZIP BIRNE ))],
           [qw( -a MOCKED-TEMPDIR FOO BAR BAZ AFFE BIRNE )],
           "patch_args");

$module->unmock_all;

like (slurp("t/zomtec.txt"), qr/affe\ntiger\nfink\nstar/, "slurp");

done_testing;
