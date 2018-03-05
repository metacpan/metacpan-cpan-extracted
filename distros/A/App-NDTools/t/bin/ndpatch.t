use strict;
use warnings FATAL => 'all';

use File::Copy qw(copy);
use File::Spec::Functions qw(catfile);
use Test::File::Contents;
use Test::More tests => 8;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

my $test;
my $bin = catfile('..', '..', '..', 'ndpatch');
my $mod = 'App::NDTools::NDPatch';
my @cmd = ($mod);

### essential tests

require_ok($mod) || BAIL_OUT("Failed to load $mod");

$test = "noargs";
run_ok(
    name => $test,
    cmd => [ "@cmd" ],
    stderr => qr/FATAL] One or two arguments expected/,
    exit => 1
);

$test = "verbose";
run_ok(
    name => $test,
    cmd => [ @cmd, qw(-vv -v4 --verbose --verbose 4 -V)],
    stderr => qr/ INFO] Exit 0/,
    stdout => qr/^\d+\.\d+/,
);

$test = "help";
run_ok(
    name => $test,
    cmd => [ $^X, $bin, '--help', '-h' ], # argv pod inside bin
    stderr => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

### bin specific tests

$test = "default";
run_ok(
    name => $test,
    pre => sub { copy("_menu.a.json", "$test.got") },
    cmd => [ @cmd, "$test.got", "$test.patch" ],
    test => sub { files_eq_or_diff("_menu.b.json", "$test.got", $test) },
);

$test = "ifmt_yaml";
run_ok(
    name => $test,
    pre => sub { copy("$test.data", "$test.got") },
    cmd => [ @cmd, '--ifmt', 'yaml', "$test.got", "$test.patch" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "ifmt_yaml_ofmt_yaml";
run_ok(
    name => $test,
    pre => sub { copy("$test.data", "$test.got") },
    cmd => [ @cmd, '--ifmt', 'yaml', '--ofmt', 'yaml', "$test.got", "$test.patch" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "stdin";
run_ok(
    name => $test,
    pre => sub { copy("_menu.b.json", "$test.got") },
    cmd => [ @cmd, "$test.got", "$test.patch" ],
    test => sub { files_eq_or_diff("_menu.a.json", "$test.got", $test) },
);

