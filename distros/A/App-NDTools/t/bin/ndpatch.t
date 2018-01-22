use strict;
use warnings FATAL => 'all';

use File::Copy qw(copy);
use Test::File::Contents;
use Test::More tests => 7;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

my $test;
my $shared = "../../_data";
my @cmd = qw/ndpatch/;

### essential tests

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
    stdout => qr/^\d+\.\d+/,
);

$test = "help";
run_ok(
    name => $test,
    cmd => [ @cmd, '--help', '-h' ],
    stderr => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

### bin specific tests

$test = "default";
run_ok(
    name => $test,
    pre => sub { copy("$shared/menu.a.json", "$test.got") },
    cmd => [ @cmd, "$test.got", "$test.patch" ],
    test => sub { files_eq_or_diff("$shared/menu.b.json", "$test.got", $test) },
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
    pre => sub { copy("$shared/menu.b.json", "$test.got") },
    cmd => [ @cmd, "$test.got", "$test.patch" ],
    test => sub { files_eq_or_diff("$shared/menu.a.json", "$test.got", $test) },
);

