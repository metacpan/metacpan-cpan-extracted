use strict;
use warnings FATAL => 'all';

use File::Copy qw(copy);
use Test::File::Contents;
use Test::More tests => 19;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

my $test;
my $mod = 'App::NDTools::NDProc';
my @cmd = ($mod, '--module', 'Merge');

require_ok($mod) || BAIL_OUT("Failed to load $mod");

$test = "dump_rules";
run_ok(
    name => $test,
    cmd => [
        @cmd, '--path', '{common}', '--dump-rules', "$test.got",
        '--source', '../beta.json', '--nostrict',
            '--path', '{fqdn}', '--style', 'L_OVERRIDE',
        '--source', '../gamma.json', '--style', 'L_REPLACE',
            '--path', '{mtime}', '--style', 'R_REPLACE',
            '--path', '{another}',
            '--path', '{one_more}', '--nostrict'
    ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "ignore";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--source', "_cfg.beta.json", '--ignore', "{files}{'/etc/hostname'}", "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "implicit_array_item_0";
run_ok(
    name => $test,
    pre => sub { copy("_menu.a.json", "$test.got") },
    cmd => [ @cmd, '--source', "_menu.b.json", '--path', '[1]{Edit}[]{id}(eq "edit_replace")(back)', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "implicit_array_item_1";
run_ok(
    name => $test,
    pre => sub { copy("_menu.a.json", "$test.got") },
    cmd => [ @cmd, '--source', "_menu.b.json", '--path', '[1]{/^Edi/}[]{id}(eq "edit_replace")(back)', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "implicit_array_item_2";
run_ok(
    name => $test,
    pre => sub { copy("_menu.a.json", "$test.got") },
    cmd => [ @cmd, '--source', "_menu.b.json", '--path', '[1]{/Edit/}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "implicit_array_item_3";
run_ok(
    name => $test,
    pre => sub { copy("_menu.a.json", "$test.got") },
    cmd => [ @cmd, '--source', "_menu.b.json", '--path', '[]{/Edit/}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "implicit_array_item_4";
run_ok(
    name => $test,
    pre => sub { copy("_menu.a.json", "$test.got") },
    cmd => [ @cmd, '--source', "_menu.b.json", '--path', '[]{/Edit/}[]{id}(eq "edit_replace")(back)', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "implicit_array_item_5";
run_ok(
    name => $test,
    pre => sub { copy("_empty_list.json", "$test.got") },
    cmd => [ @cmd, '--source', "_menu.b.json", '--path', '[]{/Edit/}[]{id}(eq "edit_replace")(back)', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "implicit_array_item_6";
run_ok(
    name => $test,
    pre => sub { copy("$test.json", "$test.got") }, # already merged with such options (double merge mustn't corrupt result)
    cmd => [ @cmd, '--source', "_menu.b.json", '--path', '[]{/Edit/}[]{id}(eq "edit_replace")(back)', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "multiargs";
run_ok(
    name => $test,
    pre => sub {
        copy("_cfg.alpha.json", "$test.0.got") and
        copy("_cfg.beta.json", "$test.1.got")
    },
    cmd => [ @cmd, '--source', "_cfg.gamma.json", "$test.0.got", "$test.1.got" ],
    test => sub {
        files_eq_or_diff("$test.0.exp", "$test.0.got", $test) and
        files_eq_or_diff("$test.1.exp", "$test.1.got", $test)
    },
    clean => [ "$test.0.got", "$test.1.got" ],
);

$test = "path";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--source', "_cfg.beta.json", '--merge', '{files}', '--merge', '{mtime}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "preserve";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--source', "_cfg.beta.json", '--style', 'R_REPLACE', '--preserve', '{fqdn}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "source_self";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--rules', "$test.rules.json", '--dump-blame', "$test.blame.got", "$test.got" ],
    test => sub {
        files_eq_or_diff("$test.exp", "$test.got", $test) and
        files_eq_or_diff("$test.blame.exp", "$test.blame.got", $test)
    },
    clean => [ "$test.got", "$test.blame.got" ],
);

$test = "sequent_merge";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--source', "_cfg.beta.json", '--source', "_cfg.gamma.json", '--dump-blame', "$test.blame.got", "$test.got" ],
    test => sub {
        files_eq_or_diff("$test.exp", "$test.got", $test) and
        files_eq_or_diff("$test.blame.exp", "$test.blame.got", $test)
    },
    clean => [ "$test.got", "$test.blame.got" ],
);

$test = "style";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--source', "_cfg.beta.json", '--merge', '{files}', '--style', 'L_OVERRIDE', '--merge', '{mtime}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "strict_default"; # strict enabled by default
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--source', "_cfg.beta.json", '--merge', '{not_exists}', "$test.got" ],
    stderr => qr/ FATAL] No such path '\{not_exists\}' in /,
    test => sub { files_eq_or_diff("_cfg.alpha.json", "$test.got", $test) },
    exit => 4,
);

$test = "strict_enabled";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--source', "_cfg.beta.json", '--strict', '--merge', '{not_exists}', "$test.got" ],
    stderr => qr/ FATAL] No such path '\{not_exists\}' in /,
    test => sub { files_eq_or_diff("_cfg.alpha.json", "$test.got", $test) },
    exit => 4,
);

$test = "strict_disabled";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--source', "_cfg.beta.json", '--strict', '--merge', '{not_exists}', '--nostrict', '--merge', '{mtime}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

