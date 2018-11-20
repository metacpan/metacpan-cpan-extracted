use strict;
use warnings FATAL => 'all';

use File::Copy qw(copy);
use Test::File::Contents;
use Test::More tests => 9;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

my $test;
my $mod = 'App::NDTools::NDProc';
my @cmd = ($mod, '--module', 'Patch');

require_ok($mod) || BAIL_OUT("Failed to load $mod");

$test = "path";
run_ok(
    name => $test,
    pre => sub { copy("_bool.a.json", "$test.got") },
    cmd => [ @cmd, '--source', "$test.patch", '--path', '{true}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "path_absent";
run_ok(
    name => $test,
    pre => sub { copy("_bool.a.json", "$test.got") },
    cmd => [ @cmd, '--source', "$test.patch", "$test.got" ],
    test => sub { files_eq_or_diff("_bool.b.json", "$test.got", $test) },
);

$test = "path_empty"; # full doc patched
run_ok(
    name => $test,
    pre => sub { copy("_bool.a.json", "$test.got") },
    cmd => [ @cmd, '--source', "$test.patch", '--path', '', "$test.got" ],
    test => sub { files_eq_or_diff("_bool.b.json", "$test.got", $test) },
);

$test = "path_strict";
run_ok(
    name => $test,
    pre => sub { copy("_bool.a.json", "$test.got") },
    cmd => [ @cmd, '--source', '_bool.b.json', '--path', '{some}{absent}{path}', '--strict', "$test.got" ],
    stderr => qr/ FATAL] Failed to lookup path /,
    exit => 4,
);

$test = "preserve";
run_ok(
    name => $test,
    pre => sub { copy("_bool.a.json", "$test.got") },
    cmd => [ @cmd, '--source', "$test.patch", '--preserve', '{true}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "source_absent";
run_ok(
    name => $test,
    pre => sub { copy("_bool.a.json", "$test.got") },
    cmd => [ @cmd, '--path', '{true}', "$test.got" ],
    stderr => qr/ FATAL] Source file should be specified/,
    exit => 1,
);

$test = "source_broken";
run_ok(
    name => $test,
    pre => sub { copy("_bool.a.json", "$test.got") },
    cmd => [ @cmd, '--source', "$test.patch", "$test.got" ],
    stderr => qr/ FATAL] Failed to decode 'JSON'/,
    exit => 4,
);

$test = "patch_mismatch";
run_ok(
    name => $test,
    pre => sub { copy("_bool.a.json", "$test.got") },
    cmd => [ @cmd, '--source', "$test.patch", '--path', '{true}', "$test.got" ],
    stderr => qr/ FATAL] Structure does not match/,
    exit => 8,
);

