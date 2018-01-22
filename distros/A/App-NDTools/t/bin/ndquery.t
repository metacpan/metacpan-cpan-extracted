use strict;
use warnings FATAL => 'all';

use File::Copy qw(copy);
use Test::File::Contents;
use Test::More tests => 39;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

my $test;
my $shared = "../../_data";
my @cmd = qw/ndquery/;

### essential tests

$test = "noargs";
run_ok(
    name => $test,
    cmd => [ "@cmd < /dev/null" ],
    stderr => qr/ FATAL] Failed to decode /,
    exit => 4
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

$test = "bool_yaml"; # YAML bool values must be correctly loaded
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/bool.yaml" ],
    stdout => sub { file_contents_eq_or_diff("$shared/bool.yaml", shift, $test) },
);

$test = "default";
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$shared/cfg.alpha.json", shift, $test) },
);

$test = "delete";
run_ok(
    name => $test,
    cmd => [ @cmd, '--delete', '{mtime}', '--delete', '{files}{"/etc/hosts"}', "$shared/cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "grep_0";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '[]{/^.i/}[1]{id}', "$shared/menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "grep_1";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '[]{}[](not defined)', "$shared/menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "grep_2";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '{files}', '--grep', '{fqdn}', "$shared/cfg.alpha.json" ],
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
    cmd => [ @cmd, '--items', '--path', '[]{}', "$shared/menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "items_bool";
run_ok(
    name => $test,
    cmd => [ @cmd, '--items', '--path', '{}[]', "$shared/bool.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "items_hash";
run_ok(
    name => $test,
    cmd => [ @cmd, '--items', "$shared/cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "items_undef";
run_ok(
    name => $test,
    cmd => [ @cmd, '--items', '--path', '[]{Edit}[](not defined)', "$shared/menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "list";
run_ok(
    name => $test,
    cmd => [ @cmd, '--list', "$shared/cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "list_colors";
run_ok(
    name => $test,
    cmd => [ @cmd, '--list', '--colors', "$shared/deep-down-lorem.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "list_depth";
run_ok(
    name => $test,
    cmd => [ @cmd, '--list', '--depth', '1', "$shared/cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "list_path";
run_ok(
    name => $test,
    cmd => [ @cmd, '--list', '--path', '{files}', "$shared/cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "list_values";
run_ok(
    name => $test,
    cmd => [ @cmd, '--list', '--values', '--vals', "$shared/menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "list_values_depth";
run_ok(
    name => $test,
    cmd => [ @cmd, '--list', '--values', '--depth', '3', "$shared/menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "md5";
run_ok(
    name => $test,
    cmd => [ @cmd, '--md5', "$shared/menu.a.json", "$shared/menu.b.json", "$shared/menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "md5_path";
run_ok(
    name => $test,
    cmd => [ @cmd, '--md5', '--path', '[0]{File}[0]{label}', "$shared/menu.a.json", "$shared/menu.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "md5_stdin";
run_ok(
    name => $test,
    cmd => [ "@cmd --md5 --path [0]{File}[0]{label} < $shared/menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "nopretty";
run_ok(
    name => $test,
    cmd => [ @cmd, '--nopretty', "$shared/cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "path_0";
run_ok(
    name => $test,
    cmd => [ @cmd, '--path', '{files}{"/etc/hosts"}', "$shared/cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "path_1";
run_ok(
    name => $test,
    cmd => [ @cmd, '--path', '[]', "$shared/menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "path_2";
run_ok(
    name => $test,
    cmd => [ @cmd, '--path', '[1]{Edit}[]{id}(eq "edit_paste")(back)', "$shared/menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "path_3";
run_ok(
    name => $test,
    cmd => [ @cmd, '--path', '[1]{Edit}[](not defined)', "$shared/menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "path_utf8";
run_ok(
    name => $test,
    cmd => [ @cmd, '--path', '{"текст"}', "$shared/text-utf8.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "ofmt_yaml";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ofmt', 'yaml', "$shared/cfg.alpha.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "raw_output_object";
run_ok(
    name => $test,
    cmd => [ @cmd, '--raw-output', '--path', '[0]{File}[1]', "$shared/menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "raw_output_string";
run_ok(
    name => $test,
    cmd => [ @cmd, '--raw-output', '--path', '[0]{File}[1]{label}', "$shared/menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
);

$test = "replace_list";
run_ok(
    name => $test,
    pre => sub { copy("$shared/cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--replace', '--list', "$test.got" ],
    test => sub { files_eq_or_diff("$shared/cfg.alpha.json", "$test.got", $test) }, # must remain unchanged
    stderr => qr/FATAL] --replace opt can't be used with --list/,
    exit => 1,
);

$test = "replace_md5";
run_ok(
    name => $test,
    pre => sub { copy("$shared/cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--replace', '--md5', "$test.got" ],
    test => sub { files_eq_or_diff("$shared/cfg.alpha.json", "$test.got", $test) }, # must remain unchanged
    stderr => qr/FATAL] --replace opt can't be used with --md5/,
    exit => 1,
);

$test = "replace_multiargs";
run_ok(
    name => $test,
    pre => sub {
        copy("$shared/cfg.alpha.json", "$test.0.got") and
        copy("$shared/cfg.beta.json", "$test.1.got")
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
    pre => sub { copy("$shared/cfg.alpha.json", "$test.got") },
    cmd => [ @cmd, '--replace', '--raw-output', '--path', '{fqdn,mtime,files}', "$test.got" ],
    test => sub { files_eq_or_diff("$test.exp", "$test.got", $test) },
);

$test = "strict";
run_ok(
    name => $test,
    cmd => [ @cmd, '--strict', '--path', '{NoTeXiStS}', "$shared/menu.a.json" ],
    stderr => qr/FATAL] Failed to lookup path '\{NoTeXiStS\}'/,
    exit => 8
);

$test = "strict_disabled";
run_ok(
    name => $test,
    cmd => [ @cmd, '--nostrict', '--path', '{NoTeXiStS}', "$shared/menu.a.json" ],
    stdout => '', # empty
);

