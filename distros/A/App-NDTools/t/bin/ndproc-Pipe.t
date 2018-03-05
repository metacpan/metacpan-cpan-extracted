use strict;
use warnings FATAL => 'all';

use File::Copy qw(copy);
use Test::File::Contents;
use Test::More tests => 9;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

my $test;
my $mod = 'App::NDTools::NDProc';
my @cmd = ($mod, '--module', 'Pipe');

require_ok($mod) || BAIL_OUT("Failed to load $mod");

$test = "cmd_absent";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--path', '{files}', "$test.got" ],
    stderr => qr/ ERROR] Command to run should be defined/,
    exit => 1
);

$test = "cmd_failed";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--path', '{files}', '--cmd', $^X . ' -e "exit 222"', "$test.got" ],
    stderr => qr/ FATAL] .* exited with 222\./,
    exit => 16
);

$test = "malformed_json";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--cmd', 'echo -n', "$test.got" ],
    stderr => qr/ FATAL] Failed to decode 'JSON'/,
    exit => 4,
);

$test = "path";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--path', '{files}', '--cmd', $^X . ' -pe "s/1/42/g"', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "path_absent";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--cmd', $^X . ' -pe "s/[0-8]/9/g"', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "path_empty"; # means 'full structure'
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--path', '', '--cmd', $^X . ' -pe "s/[0-8]/9/g"', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "path_strict";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--strict', '--path', '{not_exists}', '--cmd', $^X . ' -pe "s/[0-8]/9/g"', "$test.got" ],
    stderr => qr/ FATAL] Failed to lookup path '\{not_exists\}'/,
    exit => 4,
);

$test = "preserve";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--preserve', '{files}{"/etc/hosts"}', '--cmd', $^X . ' -pe "s/[0-8]/9/g"', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

