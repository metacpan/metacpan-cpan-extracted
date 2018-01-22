use strict;
use warnings FATAL => 'all';

use File::Copy qw(copy);
use Test::File::Contents;
use Test::More tests => 24;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

my $test;
my $shared = "../../_data";
my @cmd = qw/ndproc --module Insert/;

$test = "bool_0";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--bool', 'true', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "bool_1";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--bool', 'false', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "bool_2";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--bool', 'True', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "bool_3";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--bool', 'False', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "bool_4";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--bool', '1', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "bool_5";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--bool', '0', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "bool_6";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--bool', ' ', "$test.got" ],
    stderr => qr/ ERROR] Unsuitable value for --boolean/,
    exit => 1,
);

$test = "bool_7";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--bool', '', "$test.got" ],
    stderr => qr/ ERROR] Unsuitable value for --boolean/,
    exit => 1,
);

$test = "file";
run_ok(
    name => $test,
    pre => sub { copy("$shared/bool.a.json", "$test.got") },
    cmd => [ @cmd, '--path', '{some}[1]{path}', '--file', "$shared/text-utf8.a.json", "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "file_absent";
run_ok(
    name => $test,
    pre => sub { copy("$shared/bool.a.json", "$test.got") },
    cmd => [ @cmd, '--path', '{path}', '--file', "NotExists.json", "$test.got" ],
    stderr => qr/FATAL] Failed to open file 'NotExists.json' \(No such file or directory\)/,
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
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--number', '42', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "number_1";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--number', '3.1415', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "number_2";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--number', '6.23E24', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "number_3";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--number', '-1000', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "number_4";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--number', '+1000', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "number_5";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--number', 'garbage', "$test.got" ],
    stderr => qr/ ERROR] Unsuitable value for --number/,
    exit => 1,
);

$test = "path";
run_ok(
    name => $test,
    pre => sub { copy("$shared/bool.a.json", "$test.got") },
    cmd => [ @cmd, '--string', 'blah-blah', '--path', '{some}[0..1]{path}', '--path', '{another}[1,0]{path}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "path_absent"; # FIXME: no changes (bug?)
run_ok(
    name => $test,
    pre => sub { copy("$shared/bool.a.json", "$test.got") },
    cmd => [ @cmd, '--string', 'blah-blah', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "path_empty"; # means 'full structure'
run_ok(
    name => $test,
    pre => sub { copy("$shared/bool.a.json", "$test.got") },
    cmd => [ @cmd, '--path', '', '--string', 'blah-blah', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "string";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--string', 'blah-blah', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "undef_0";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--undef', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "undef_1";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', '--null', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "value_absent";
run_ok(
    name => $test,
    pre => sub { copy("$shared/empty_hash.json", "$test.got") },
    cmd => [ @cmd, '--path', '{value}', "$test.got" ],
    stderr => qr/ERROR] Value to insert should be defined/,
    exit => 1,
);

