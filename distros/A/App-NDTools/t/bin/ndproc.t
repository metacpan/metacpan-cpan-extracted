use strict;
use warnings FATAL => 'all';

use File::Copy qw(copy);
use File::Spec::Functions qw(catfile);
use Test::File::Contents;
use Test::More tests => 26;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

my $test;
my $bin = catfile('..', '..', '..', 'ndproc');
my $mod = 'App::NDTools::NDProc';
my @cmd = ($mod);

### essential tests

require_ok($mod) || BAIL_OUT("Failed to load $mod");

$test = "noargs";
run_ok(
    name => $test,
    cmd => [ @cmd ],
    stderr => qr/ FATAL] At least one argument expected/,
    exit => 1
);

$test = "verbose";
run_ok(
    name => $test,
    cmd => [ @cmd, '-vv', '-v4', '--verbose', '--verbose', '4', '-V'],
    stderr => qr/ TRACE] Indexing modules/, # FIXME: there must be no actions on -V
    stdout => qr/^\d+\.\d+/,
);

my $orig_program_name = $0;
$0 = $bin; # Pod::Usage will be able to find binary with pod
$test = "help";
run_ok(
    name => $test,
    cmd => [ @cmd, '--help', '-h' ],
    stderr => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);
$0 = $orig_program_name; # just in case

$test = "unsupported_mod_opt";
run_ok(
    name => $test,
    cmd => [ @cmd, '-m', 'Pipe', '--unsupported-opt' ],
    stderr => qr/Name:\n    Pipe /,
    exit => 1
);

### bin specific tests

$test = "blame_disabled";
run_ok(
    name => $test,
    pre => sub { copy("_menu.a.json", "$test.got") },
    cmd => [ @cmd, '--module', 'Remove', '--path', '[1]{Edit}[3..5]', '--noblame', '--dump-blame', "$test.blame.got", "$test.got" ],
    test => sub { files_eq_or_diff("$test.blame.exp", "$test.blame.got", $test) },
    clean => [ "$test.blame.got", "$test.got" ],
);

$test = "blame_dump";
run_ok(
    name => $test,
    pre => sub { copy("_menu.a.json", "$test.got") },
    cmd => [ @cmd, '--module', 'Remove', '--path', '[1]{Edit}[3..5]', '--dump-blame', "$test.blame.got", "$test.got" ],
    test => sub { files_eq_or_diff("$test.blame.exp", "$test.blame.got", $test) },
    clean => [ "$test.blame.got", "$test.got" ],
);

$test = "blame_embed";
run_ok(
    name => $test,
    pre => sub { copy("_menu.a.json", "$test.got") },
    cmd => [ @cmd, '--module', 'Remove', '--path', '[1]{Edit}[3..5]', '--embed-blame', '[1]{Edit}[3]{_blame_}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "ifmt_yaml";
run_ok(
    name => $test,
    pre => sub { copy("$test.data", "$test.got") },
    cmd => [ @cmd, '--ifmt', 'yaml', '--module', 'Merge', '--source', "$test.merge", "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "ifmt_yaml_ofmt_yaml";
run_ok(
    name => $test,
    pre => sub { copy("$test.data", "$test.got") },
    cmd => [ @cmd, '--ifmt', 'yaml', '--ofmt', 'yaml', '--module', 'Merge', '--source', "$test.merge", "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "list_modules";
run_ok(
    name => $test,
    cmd => [ @cmd, qw/-l --list-modules/ ],
    stdout => qr/^\w+\s+[\d\.]+\s+\S/m,
);

$test = "module_disabled_0";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--rules', "$test.rules.json", '--disable-module', 'Insert', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);
$test = "module_disabled_1";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--rules', "$test.rules.json", '--disable-module', 'Remove', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);
$test = "module_disabled_1";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--rules', "$test.rules.json", '--disable-module', 'Insert', '--disable-module', 'Remove', "$test.got" ],
    test => sub { files_eq_or_diff("_cfg.alpha.json", "$test.got", $test) },
);

$test = "module_not_exists";
run_ok(
    name => $test,
    cmd => [ @cmd, qw/--module NoTeXiStS/ ],
    stderr => qr/ FATAL] Unknown module specified 'NoTeXiStS'/,
    exit => 1
);

$test = "module_unsupported_opt";
run_ok(
    name => $test,
    cmd => [ @cmd, qw/--module Remove --unsupported-opt-test/ ],
    stderr => qr/Unknown option: unsupported-opt-test/,
    exit => 1
);

$test = "multiargs";
run_ok(
    name => $test,
    pre => sub {
        copy("_menu.a.json", "$test.a.got") and
        copy("_menu.b.json", "$test.b.got")
    },
    cmd => [ @cmd, '--module', 'Remove', '--path', '[1]{Edit}[3..5]', "$test.a.got", "$test.b.got" ],
    test => sub {
        files_eq_or_diff("$test.a.exp", "$test.a.got", $test) and
        files_eq_or_diff("$test.b.exp", "$test.b.got", $test)
    },
    clean => [ "$test.a.got", "$test.b.got" ],
);

$test = "rules";
run_ok(
    name => $test,
    pre => sub { copy("_menu.a.json", "$test.got") },
    cmd => [ @cmd, '--rules', "$test.rules.json", "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "rules_builtin";
run_ok(
    name => $test,
    pre => sub { copy("$test.json", "$test.got") },
    cmd => [ @cmd, '--builtin-rules', '[3]{builtin}{rules}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "rules_builtin_dump";
run_ok(
    name => $test,
    cmd => [ @cmd, '--builtin-rules', '[3]{builtin}{rules}', '--dump-rules', "$test.got", "$test.json" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "rules_builtin_format_json";
run_ok(
    name => $test,
    pre => sub { copy("$test.json", "$test.got") },
    cmd => [ @cmd, '--builtin-format', 'JSON', '--builtin-rules', '[3]{builtin}{rules}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "rules_dump";
run_ok(
    name => $test,
    cmd => [ @cmd, '--module', 'Remove', '--path', '{some}[0..5]', '--dump-rules', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "rules_embed"; # process and embed
run_ok(
    name => $test,
    pre => sub { copy("_menu.a.json", "$test.got") },
    cmd => [ @cmd, '--rules', "$test.rules.json", '--embed-rules', '[3]{builtin}{rules}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "rules_redump";
run_ok(
    name => $test,
    cmd => [ @cmd, '--rules', "$test.exp", '--dump-rules', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "rules_unknown_module";
run_ok(
    name => $test,
    pre => sub { copy("_menu.a.json", "$test.got") },
    cmd => [ @cmd, '--rules', "$test.rules.json", "$test.got" ],
    stderr => qr/ FATAL] Unknown module specified \(UnKn0wn-M0duLe_n\@me; rule #1\)/,
    exit => 1
);

SKIP: {
    skip "Don't know how to test pipes on win32", 1 if ($^O eq 'MSWin32');

    $test = "stdin_stdout";
    run_ok(
        name => $test,
        cmd => [ "$^X -pe '' _cfg.alpha.json | $^X $bin --module Remove --path '{files}' -" ],
        stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    );
}

