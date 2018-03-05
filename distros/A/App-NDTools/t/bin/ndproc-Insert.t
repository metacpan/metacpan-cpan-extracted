use strict;
use warnings FATAL => 'all';

use File::Copy qw(copy);
use File::Spec::Functions qw(catfile);
use Test::File::Contents;
use Test::More tests => 25;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

my $test;
my $bin = catfile('..', '..', '..', 'ndproc');
my $mod = 'App::NDTools::NDProc';
my @cmd = ($mod, '--module', 'Insert');

require_ok($mod) || BAIL_OUT("Failed to load $mod");

$test = "bool_0";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--bool', 'true', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "bool_1";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--bool', 'false', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "bool_2";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--bool', 'True', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "bool_3";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--bool', 'False', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "bool_4";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--bool', '1', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "bool_5";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--bool', '0', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "bool_6";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ $^X, $bin, '-m','Insert', '--path', '{value}', '--bool', ' ', "$test.got" ], # FIXME: get rid of exit(0) in arg parser and use mod here
    stderr => qr/ ERROR] Unsuitable value for --boolean/,
    exit => 1,
);

$test = "bool_7";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ $^X, $bin, '-m','Insert', '--path', '{value}', '--bool', '', "$test.got" ], # FIXME: get rid of exit(0) in arg parser and use mod here
    stderr => qr/ ERROR] Unsuitable value for --boolean/,
    exit => 1,
);

$test = "file";
run_ok(
    name => $test,
    pre => sub { copy("_bool.a.json", "$test.got") },
    cmd => [ @cmd, '--path', '{some}[1]{path}', '--file', "_text-utf8.a.json", "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "file_absent";
run_ok(
    name => $test,
    pre => sub { copy("_bool.a.json", "$test.got") },
    cmd => [ @cmd, '--path', '{path}', '--file', "NotExists.json", "$test.got" ],
    stderr => qr/FATAL] Failed to open file 'NotExists.json'/,
    exit => 2,
);

$test = "file_fmt_raw";
run_ok(
    name => $test,
    pre => sub { copy("$test.a.json", "$test.got") },
    cmd => [ @cmd, qw(--path {new}{path} --file-fmt RAW --file), "$test.b.json", "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "number_0";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--number', '42', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "number_1";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--number', '3.1415', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

SKIP: {
    skip "Scientific notation differs on win32 (6.23e+24 vs 6.23e+024)",
        1 if ($^O eq 'MSWin32');

    $test = "number_2";
    run_ok(
        name => $test,
        pre => sub { copy("_empty_hash.json", "$test.got") },
        cmd => [ @cmd, '--path', '{value}', '--number', '6.23E24', "$test.got" ],
        test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
    );
}

$test = "number_3";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--number', '-1000', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "number_4";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--number', '+1000', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "number_5";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ $^X, $bin, '-m','Insert', '--path', '{value}', '--number', 'garbage', "$test.got" ], # FIXME: get rid of exit(0) in arg parser and use mod here
    stderr => qr/ ERROR] Unsuitable value for --number/,
    exit => 1,
);

$test = "path";
run_ok(
    name => $test,
    pre => sub { copy("_bool.a.json", "$test.got") },
    cmd => [ @cmd, '--string', 'blah-blah', '--path', '{some}[0..1]{path}', '--path', '{another}[1,0]{path}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "path_absent"; # FIXME: no changes (bug?)
run_ok(
    name => $test,
    pre => sub { copy("_bool.a.json", "$test.got") },
    cmd => [ @cmd, '--string', 'blah-blah', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "path_empty"; # means 'full structure'
run_ok(
    name => $test,
    pre => sub { copy("_bool.a.json", "$test.got") },
    cmd => [ @cmd, '--path', '', '--string', 'blah-blah', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "string";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--string', 'blah-blah', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "undef_0";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--undef', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "undef_1";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--null', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "value_absent";
run_ok(
    name => $test,
    pre => sub { copy("_empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', "$test.got" ],
    stderr => qr/ERROR] Value to insert should be defined/,
    exit => 1,
);

