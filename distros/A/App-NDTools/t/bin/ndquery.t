use strict;
use warnings FATAL => 'all';

use File::Copy qw(copy);
use File::Spec::Functions qw(catfile);
use Test::File::Contents;
use Test::More tests => 44;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

my $test;
my $bin = catfile('..', '..', '..', 'ndquery');
my $mod = 'App::NDTools::NDQuery';
my @cmd = ($mod);

### essential tests

require_ok($mod) || BAIL_OUT("Failed to load $mod");

SKIP: {
    skip "Unix specific", 1 if ($^O eq 'MSWin32');

    $test = "noargs";
    run_ok(
        name => $test,
        cmd => [ "$^X $bin < /dev/null" ],
        stderr => qr/ FATAL] Failed to decode /,
        exit => 4
    );
}

$test = "verbose";
run_ok(
    name => $test,
    cmd => [ @cmd, qw(-vv -v4 --verbose --verbose 4 -V)],
    stderr => qr/ INFO] Exit 0,/,
    stdout => qr/^\d+\.\d+/,
);

$test = "help";
run_ok(
    name => $test,
    cmd => [ $^X, $bin, '--help', '-h' ],
    stderr => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

### bin specific tests

$test = "bool_yaml"; # YAML bool values must be correctly loaded
run_ok(
    name => $test,
    cmd => [ @cmd, "_bool.yaml" ],
    stdout => sub { file_contents_eq_or_diff("_bool.yaml", shift, $test) },
);

$test = "default";
run_ok(
    name => $test,
    cmd => [ @cmd, "_cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("_cfg.alpha.json", shift, $test) },
);

$test = "delete";
run_ok(
    name => $test,
    cmd => [ @cmd, '--delete', '{mtime}', '--delete', '{files}{"/etc/hosts"}', "_cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "grep_0";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '[]{/^.i/}[1]{id}', "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "grep_1";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '[]{}[](not defined)', "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "grep_2";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '{files}', '--grep', '{fqdn}', "_cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "grep_3";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '[1]{Edit}[-1,-3]', "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "grep_4";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '[2,0]', "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "grep_5";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '[2,0]{}[]{id}', "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "grep_6";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '[2,0]{}[]{id}', '--grep', '[0,2]{}[1]{label}', "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "ifmt_yaml";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ifmt', 'yaml', "$test.data" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "ifmt_yaml_ofmt_yaml";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ifmt', 'yaml', '--ofmt', 'yaml', "$test.data" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "items_array";
run_ok(
    name => $test,
    cmd => [ @cmd, '--keys', '--path', '[]{}', "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "items_bool";
run_ok(
    name => $test,
    cmd => [ @cmd, '--keys', '--path', '{}[]', "_bool.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "items_hash";
run_ok(
    name => $test,
    cmd => [ @cmd, '--keys', "_cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "items_undef";
run_ok(
    name => $test,
    cmd => [ @cmd, '--keys', '--path', '[]{Edit}[](not defined)', "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "list";
run_ok(
    name => $test,
    cmd => [ @cmd, '--list', "_cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "list_colors";
run_ok(
    name => $test,
    cmd => [ @cmd, '--list', '--colors', "_deep-down-lorem.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "list_depth";
run_ok(
    name => $test,
    cmd => [ @cmd, '--list', '--depth', '1', "_cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "list_path";
run_ok(
    name => $test,
    cmd => [ @cmd, '--list', '--path', '{files}', "_cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "list_values";
run_ok(
    name => $test,
    cmd => [ @cmd, '--list', '--values', '--vals', "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "list_values_depth";
run_ok(
    name => $test,
    cmd => [ @cmd, '--list', '--values', '--depth', '3', "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "md5";
run_ok(
    name => $test,
    cmd => [ @cmd, '--md5', "_menu.a.json", "_menu.b.json", "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "md5_path";
run_ok(
    name => $test,
    cmd => [ @cmd, '--md5', '--path', '[0]{File}[0]{label}', "_menu.a.json", "_menu.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "md5_stdin";
run_ok(
    name => $test,
    cmd => [ "$^X $bin --md5 --path [0]{File}[0]{label} < _menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "nopretty";
run_ok(
    name => $test,
    cmd => [ @cmd, '--nopretty', "_cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "path_0";
run_ok(
    name => $test,
    cmd => [ @cmd, '--path', '{files}{"/etc/hosts"}', "_cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "path_1";
run_ok(
    name => $test,
    cmd => [ @cmd, '--path', '[]', "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "path_2";
run_ok(
    name => $test,
    cmd => [ @cmd, '--path', '[1]{Edit}[]{id}(eq "edit_paste")(back)', "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "path_3";
run_ok(
    name => $test,
    cmd => [ @cmd, '--path', '[1]{Edit}[](not defined)', "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

SKIP: {
    skip "non utf8 locale", 1 unless (exists $ENV{LC_ALL} and $ENV{LC_ALL} =~ /UTF-8/);

    $test = "path_utf8";
    run_ok(
        name => $test,
        cmd => [ @cmd, '--path', '{"текст"}', "_text-utf8.a.json" ],
        stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test, { encoding => 'UTF-8' }) },
    );
}

$test = "ofmt_yaml";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ofmt', 'yaml', "_cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "raw_output_object";
run_ok(
    name => $test,
    cmd => [ @cmd, '--raw-output', '--path', '[0]{File}[1]', "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "raw_output_string";
run_ok(
    name => $test,
    cmd => [ @cmd, '--raw-output', '--path', '[0]{File}[1]{label}', "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "replace_list";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--replace', '--list', "$test.got" ],
    test => sub { files_eq_or_diff("_cfg.alpha.json", "$test.got", $test) }, # must remain unchanged
    stderr => qr/FATAL] --replace opt can't be used with --list/,
    exit => 1,
);

$test = "replace_md5";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--replace', '--md5', "$test.got" ],
    test => sub { files_eq_or_diff("_cfg.alpha.json", "$test.got", $test) }, # must remain unchanged
    stderr => qr/FATAL] --replace opt can't be used with --md5/,
    exit => 1,
);

$test = "replace_multiargs";
run_ok(
    name => $test,
    pre => sub {
        copy("_cfg.alpha.json", "$test.0.got") and
        copy("_cfg.beta.json", "$test.1.got")
    },
    cmd => [ @cmd, '--replace', '--delete', '{mtime}', "$test.0.got", "$test.1.got" ],
    test => sub {
        files_eq_or_diff("$test.0.exp", "$test.0.got", $test) and
        files_eq_or_diff("$test.1.exp", "$test.1.got", $test)
    },
    clean => [ "$test.0.got", "$test.1.got" ],
);

$test = "replace_raw_output";
run_ok(
    name => $test,
    pre => sub { copy("_cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--replace', '--raw-output', '--path', '{fqdn,mtime,files}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "strict";
run_ok(
    name => $test,
    cmd => [ @cmd, '--strict', '--path', '{NoTeXiStS}', "_menu.a.json" ],
    stderr => qr/FATAL] Failed to lookup path '\{NoTeXiStS\}'/,
    exit => 8
);

$test = "strict_disabled";
run_ok(
    name => $test,
    cmd => [ @cmd, '--nostrict', '--path', '{NoTeXiStS}', "_menu.a.json" ],
    stdout => '', # empty
);

