use strict;
use warnings FATAL => 'all';

use File::Copy qw(copy);
use Test::File::Contents;
use Test::More tests => 6;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

my $test;
my $mod = 'App::NDTools::NDProc';
my @cmd = ($mod, '--module', 'Remove');

require_ok($mod) || BAIL_OUT("Failed to load $mod");

$test = "path";
run_ok(
    name => $test,
    pre => sub { copy("_deep-down-lorem.a.json", "$test.got") },
    cmd => [ @cmd, '--path', '{some}[0..5]', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "path_absent";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, "$test.got" ],
    stderr => qr/ FATAL] At least one path should be specified/,
    exit => 1,
);

$test = "path_empty"; # full doc removed
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "path_strict";
run_ok(
    name => $test,
    pre => sub { copy("_deep-down-lorem.a.json", "$test.got") },
    cmd => [ @cmd, '--path', '{some}[1000]', '--strict', "$test.got" ],
    stderr => qr/ FATAL] Failed to lookup path '\{some\}\[1000\]'/,
    exit => 4,
);

$test = "preserve";
run_ok(
    name => $test,
    pre => sub { copy("_menu.a.json", "$test.got") },
    cmd => [ @cmd, '--path', '[]', '--preserve', '[]{}[]{id}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

