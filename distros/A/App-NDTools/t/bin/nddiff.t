use strict;
use warnings FATAL => 'all';

use Test::File::Contents;
use Test::More tests => 52;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

my $test;
my $shared = "../../_data";
my @cmd = qw/nddiff/;

### essential tests

$test = "noargs";
run_ok(
    name => $test,
    cmd => [ @cmd ],
    stderr => qr/ERROR] Two arguments expected for diff/,,
    exit => 1,
);

$test = "verbose";
run_ok(
    name => $test,
    cmd => [ @cmd, qw(-vv -v4 --verbose --verbose 4 -V)],
    stdout => qr/^\d+\.\d+/,
    exit => 0,
);

$test = "help";
run_ok(
    name => $test,
    cmd => [ @cmd, '--help', '-h' ],
    stderr => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 0,
);

### bin specific tests

$test = "ifmt_yaml";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ifmt', 'yaml', "$test.a.data", "$test.b.data" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "ifmt_yaml_ofmt_yaml";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ifmt', 'yaml', '--ofmt', 'yaml', "$test.a.data", "$test.b.data" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "json";
run_ok(
    name => $test,
    cmd => [ @cmd, '--json', "$shared/cfg.alpha.json", "$shared/cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "json_ignore";
run_ok(
    name => $test,
    cmd => [
        @cmd, '--json', '--full', '--ignore', '{some}[5]{text}[0]{buried}[1]{"deep down"}{in}[0]{"the structure"}',
        "$shared/deep-down-lorem.a.json", "$shared/deep-down-lorem.b.json"
    ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 0, # no diff here
);

$test = "json_ignore_incorrect_path";
run_ok(
    name => $test,
    cmd => [ @cmd, '--json', '--ignore', 'incorrect path', "$shared/menu.a.json", "$shared/menu.b.json" ],
    stderr => qr/FATAL] Failed to parse 'incorrect path'/,
    exit => 4,
);

$test = "json_ignore_unexisted_path";
run_ok(
    name => $test,
    cmd => [ @cmd, '--json', '--full', '--ignore', '[1]{notexists}[5]', "$shared/menu.a.json", "$shared/menu.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "json_nodiff";
run_ok(
    name => $test,
    cmd => [ @cmd, '--json', "$shared/cfg.alpha.json", "$shared/cfg.alpha.json" ],
    stdout => "{}\n",
);

$test = "json_nopretty";
run_ok(
    name => $test,
    cmd => [ @cmd, '--json', '--nopretty', "$shared/cfg.alpha.json", "$shared/cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "json_numbers";
run_ok(
    name => $test,
    cmd => [ @cmd, '--json', "$shared/numbers.a.json", "$shared/numbers.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "ofmt_yaml";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ofmt', 'yaml', "$shared/cfg.alpha.json", "$shared/cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "rules";
run_ok(
    name => $test,
    cmd => [ @cmd, '--rules', "$shared/cfg.alpha.json", "$shared/cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_array_0";
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/menu.a.json", "$shared/menu.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_array_1";
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/menu.b.json", "$shared/menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_bool";
run_ok(
    name => $test,
    cmd => [ @cmd, '--nopretty', "$shared/bool.a.json", "$shared/bool.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_brief";
run_ok(
    name => $test,
    cmd => [ @cmd, '--brief', "$shared/menu.a.json", "$shared/menu.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_brief_colors";
run_ok(
    name => $test,
    cmd => [ @cmd, '--brief', '--colors', "$shared/bool.a.json", "$shared/bool.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_colors";
run_ok(
    name => $test,
    cmd => [ @cmd, '--colors', "$shared/cfg.alpha.json", "$shared/cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_full_headers";
run_ok(
    name => $test,
    cmd => [ @cmd, '--full-headers', "$shared/cfg.alpha.json", "$shared/cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_grep_1";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '{list}[1]', "$shared/bool.a.json", "$shared/bool.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_grep_2";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '{fqdn}', '--grep', '{mtime}', "$shared/cfg.alpha.json", "$shared/cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_grep_utf8_path";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '{"текст"}', "$shared/text-utf8.a.json", "$shared/text-utf8.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_hash";
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/cfg.alpha.json", "$shared/cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_nodiff";
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/menu.a.json", "$shared/menu.a.json" ],
);

$test = "term_nopretty";
run_ok(
    name => $test,
    cmd => [ @cmd, '--nopretty', "$shared/menu.a.json", "$shared/menu.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_show";
run_ok(
    name => $test,
    cmd => [ @cmd, '--show', "$test.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_show_brief";
run_ok(
    name => $test,
    cmd => [ @cmd, '--show', '--brief', "$test.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_quiet";
run_ok(
    name => $test,
    cmd => [ @cmd, '--quiet', "$shared/bool.a.json", "$shared/bool.b.json" ],
    stdout => '',
    exit => 8,
);

$test = "term_subkey_AR";
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/struct-subkey-AR.a.json", "$shared/struct-subkey-AR.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text";
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/deep-down-lorem.a.json", "$shared/deep-down-lorem.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_AR_0";
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/text-AR.a.json", "$shared/text-AR.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_AR_1";
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/text-AR.b.json", "$shared/text-AR.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

# check that sequences of changed lines grouped by removed and added blocks
$test = "term_text_changed_seqs";
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/text-changed-seqs.a.json", "$shared/text-changed-seqs.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_00";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '0', "$shared/text-changed-seqs.a.json", "$shared/text-changed-seqs.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_01";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '1', "$shared/text-changed-seqs.a.json", "$shared/text-changed-seqs.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);
$test = "term_text_ctx_02";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '2', "$shared/text-changed-seqs.a.json", "$shared/text-changed-seqs.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_03";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '3', "$shared/text-changed-seqs.a.json", "$shared/text-changed-seqs.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_04";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '0', "$shared/text-utf8.a.json", "$shared/text-utf8.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_05";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '1', "$shared/text-utf8.a.json", "$shared/text-utf8.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_06";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '2', "$shared/text-utf8.a.json", "$shared/text-utf8.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_07";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '3', "$shared/text-utf8.a.json", "$shared/text-utf8.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_08";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '9', "$shared/text-utf8.a.json", "$shared/text-utf8.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_09";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '0', "$shared/deep-down-lorem.a.json", "$shared/deep-down-lorem.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_10";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '0', "$shared/text-AR.a.json", "$shared/text-AR.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_11";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '1', "$shared/text-AR.a.json", "$shared/text-AR.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_newlines_0";
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/text-newlines.a.json", "$shared/text-newlines.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_newlines_1";
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/text-newlines.b.json", "$shared/text-newlines.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_newlines_2";
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/text-newlines2.a.json", "$shared/text-newlines2.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_newlines_3";
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/text-newlines2.b.json", "$shared/text-newlines2.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_utf8";
run_ok(
    name => $test,
    cmd => [ @cmd, "$shared/text-utf8.a.json", "$shared/text-utf8.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

