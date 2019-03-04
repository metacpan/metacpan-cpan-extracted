use strict;
use warnings FATAL => 'all';

use File::Spec::Functions qw(catfile);
use Test::File::Contents;
use Test::More tests => 79;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

my $test;
my $bin = catfile('..', '..', '..', 'nddiff');
my $mod = 'App::NDTools::NDDiff';
my @cmd = ($mod);

### essential tests

require_ok($mod) || BAIL_OUT("Failed to load $mod");

$test = "noargs";
run_ok(
    name => $test,
    cmd => [ @cmd ],
    stderr => qr/FATAL] At least two arguments expected for diff/,
    exit => 1,
);

$test = "verbose";
run_ok(
    name => $test,
    cmd => [ @cmd, qw(-vv -v4 --verbose --verbose 4 -V)],
    stderr => qr/ INFO] Exit 0,/,
    stdout => qr/^\d+\.\d+/,
    exit => 0,
);

my $orig_program_name = $0;
$0 = $bin; # Pod::Usage will be able to find binary with pod
$test = "help";
run_ok(
    name => $test,
    cmd => [ @cmd, '--help', '-h' ], # argv pod inside bin
    stderr => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 0,
);
$0 = $orig_program_name; # just in case

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
    cmd => [ @cmd, '--json', "_cfg.alpha.json", "_cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "json_U";
run_ok(
    name => $test,
    cmd => [ @cmd, '--json', '--U', "_menu.a.json", "_menu.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "json_ignore";
run_ok(
    name => $test,
    cmd => [
        @cmd, '--json', '--U', '--ignore', '{some}[5]{text}[0]{buried}[1]{"deep down"}{in}[0]{"the structure"}',
        "_deep-down-lorem.a.json", "_deep-down-lorem.b.json"
    ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 0, # no diff here
);

$test = "json_ignore_incorrect_path";
run_ok(
    name => $test,
    cmd => [ @cmd, '--json', '--ignore', 'incorrect path', "_menu.a.json", "_menu.b.json" ],
    stderr => qr/FATAL] Failed to parse 'incorrect path'/,
    exit => 4,
);

$test = "json_ignore_unexisted_path";
run_ok(
    name => $test,
    cmd => [ @cmd, '--json', '--U', '--ignore', '[1]{notexists}[5]', "_menu.a.json", "_menu.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "json_nodiff";
run_ok(
    name => $test,
    cmd => [ @cmd, '--json', "_cfg.alpha.json", "_cfg.alpha.json" ],
    stdout => "{}\n",
);

$test = "json_nopretty";
run_ok(
    name => $test,
    cmd => [ @cmd, '--json', '--nopretty', "_cfg.alpha.json", "_cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "json_numbers";
run_ok(
    name => $test,
    cmd => [ @cmd, '--json', "_numbers.a.json", "_numbers.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "json_omitted_index";
run_ok(
    name => $test,
    cmd => [ @cmd, '--json', "_omitted_index.a.json", "_omitted_index.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "ofmt_jsonmergepatch";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ofmt', "jsonmergepatch", "_bool.a.json", "_bool.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "ofmt_jsonpatch";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ofmt', "jsonpatch", "_cfg.alpha.json", "_cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

# replacement for deprecated --rules
$test = "ofmt_rules";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ofmt', 'rules', "_bool.a.json", "_bool.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "ofmt_yaml";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ofmt', 'yaml', "_cfg.alpha.json", "_cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "rules";
run_ok(
    name => $test,
    cmd => [ @cmd, '--rules', "_bool.a.json", "_bool.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_array_0";
run_ok(
    name => $test,
    cmd => [ @cmd, "_menu.a.json", "_menu.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_array_1";
run_ok(
    name => $test,
    cmd => [ @cmd, "_menu.b.json", "_menu.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_bool";
run_ok(
    name => $test,
    cmd => [ @cmd, "_bool.a.json", "_bool.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_brief";
run_ok(
    name => $test,
    cmd => [ @cmd, '--brief', "_menu.a.json", "_menu.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_brief_nonref";
run_ok(
    name => $test,
    cmd => [ @cmd, '--brief', "$test.a.data", "$test.b.data" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_brief_colors";
run_ok(
    name => $test,
    cmd => [ @cmd, '--brief', '--colors', "_bool.a.json", "_bool.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_colors";
run_ok(
    name => $test,
    cmd => [ @cmd, '--colors', "_cfg.alpha.json", "_cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_colors_wU";
run_ok(
    name => $test,
    cmd => [ @cmd, '--colors', '-U', "_cfg.alpha.json", "_cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_grep_1";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '{list}[1]', "_bool.a.json", "_bool.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_grep_2";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '{fqdn}', '--grep', '{mtime}', "_cfg.alpha.json", "_cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_grep_absent_part";
run_ok(
    name => $test,
    cmd => [ @cmd, '--grep', '[1]{Edit}[5]{id}', "_menu.a.json", "_menu.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

SKIP: {
    skip "non utf8 locale", 1 unless (exists $ENV{LC_ALL} and $ENV{LC_ALL} =~ /UTF-8/);

    $test = "term_grep_utf8_path";
    run_ok(
        name => $test,
        cmd => [ @cmd, '--grep', '{"текст"}', "_text-utf8.a.json", "_text-utf8.b.json" ],
        stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test, { encoding => 'UTF-8' }) },
        exit => 8,
    );
}

$test = "term_hash";
run_ok(
    name => $test,
    cmd => [ @cmd, "_cfg.alpha.json", "_cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_noA";
run_ok(
    name => $test,
    cmd => [ @cmd, '--noA', "_struct-subkey-AR.a.json", "_struct-subkey-AR.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_noAR";
run_ok(
    name => $test,
    cmd => [ @cmd, '--noA', '--noR', "_struct-subkey-AR.a.json", "_struct-subkey-AR.b.json" ],
    exit => 0, # yep, no diff
);

$test = "term_noN";
run_ok(
    name => $test,
    cmd => [ @cmd, '--noN', "_cfg.alpha.json", "_cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_noNO";
run_ok(
    name => $test,
    cmd => [ @cmd, '--noN', '--noO', "_cfg.alpha.json", "_cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_noO";
run_ok(
    name => $test,
    cmd => [ @cmd, '--noO', "_cfg.alpha.json", "_cfg.beta.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_noR";
run_ok(
    name => $test,
    cmd => [ @cmd, '--noR', "_struct-subkey-AR.a.json", "_struct-subkey-AR.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_wU";
run_ok(
    name => $test,
    cmd => [ @cmd, '--U', "_bool.a.json", "_bool.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_nodiff";
run_ok(
    name => $test,
    cmd => [ @cmd, "_menu.a.json", "_menu.a.json" ],
);

$test = "term_nopretty";
run_ok(
    name => $test,
    cmd => [ @cmd, '--nopretty', "_menu.a.json", "_menu.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_nopretty_AR"; # Should be separated paths for A and R items
run_ok(
    name => $test,
    cmd => [ @cmd, '--nopretty', "_bool.a.json", "_bool.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_omitted_index";
run_ok(
    name => $test,
    cmd => [ @cmd, "_omitted_index.a.json", "_omitted_index.b.json" ],
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

$test = "term_show_blame";
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

$test = "term_show_invalid";
run_ok(
    name => $test,
    cmd => [ @cmd, '--show', "$test.json" ],
    stderr => qr/ FATAL] Diff validation failed\. /,
    exit => 1,
);

$test = "term_show_noargs";
run_ok(
    name => $test,
    cmd => [ @cmd, '--show' ],
    stderr => qr/ FATAL] At least one argument expected when --show used\. /,
    exit => 1,
);

$test = "term_show_text";
run_ok(
    name => $test,
    cmd => [ @cmd, '--show', "$test.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_string_vs_number";
run_ok(
    name => $test,
    cmd => [ @cmd, "$test.a.json", "$test.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_quiet";
run_ok(
    name => $test,
    cmd => [ @cmd, '--quiet', "_bool.a.json", "_bool.b.json" ],
    stdout => '',
    exit => 8,
);

$test = "term_subkey_AR";
run_ok(
    name => $test,
    cmd => [ @cmd, "_struct-subkey-AR.a.json", "_struct-subkey-AR.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text";
run_ok(
    name => $test,
    cmd => [ @cmd, "_deep-down-lorem.a.json", "_deep-down-lorem.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_AR_0";
run_ok(
    name => $test,
    cmd => [ @cmd, "_text-AR.a.json", "_text-AR.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_AR_1";
run_ok(
    name => $test,
    cmd => [ @cmd, "_text-AR.b.json", "_text-AR.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

# check that sequences of changed lines grouped by removed and added blocks
$test = "term_text_changed_seqs";
run_ok(
    name => $test,
    cmd => [ @cmd, "_text-changed-seqs.a.json", "_text-changed-seqs.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_00";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '0', "_text-changed-seqs.a.json", "_text-changed-seqs.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_01";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '1', "_text-changed-seqs.a.json", "_text-changed-seqs.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);
$test = "term_text_ctx_02";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '2', "_text-changed-seqs.a.json", "_text-changed-seqs.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_03";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '3', "_text-changed-seqs.a.json", "_text-changed-seqs.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_04";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '0', "_text-utf8.a.json", "_text-utf8.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test, { encoding => 'UTF-8' }) },
    exit => 8,
);

$test = "term_text_ctx_05";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '1', "_text-utf8.a.json", "_text-utf8.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test, { encoding => 'UTF-8' }) },
    exit => 8,
);

$test = "term_text_ctx_06";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '2', "_text-utf8.a.json", "_text-utf8.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test, { encoding => 'UTF-8' }) },
    exit => 8,
);

$test = "term_text_ctx_07";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '3', "_text-utf8.a.json", "_text-utf8.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test, { encoding => 'UTF-8' }) },
    exit => 8,
);

$test = "term_text_ctx_08";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '9', "_text-utf8.a.json", "_text-utf8.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test, { encoding => 'UTF-8' }) },
    exit => 8,
);

$test = "term_text_ctx_09";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '0', "_deep-down-lorem.a.json", "_deep-down-lorem.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_10";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '0', "_text-AR.a.json", "_text-AR.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_ctx_11";
run_ok(
    name => $test,
    cmd => [ @cmd, '--ctx-text', '1', "_text-AR.a.json", "_text-AR.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_newlines_0";
run_ok(
    name => $test,
    cmd => [ @cmd, "_text-newlines.a.json", "_text-newlines.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_newlines_1";
run_ok(
    name => $test,
    cmd => [ @cmd, "_text-newlines.b.json", "_text-newlines.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_newlines_2";
run_ok(
    name => $test,
    cmd => [ @cmd, "_text-newlines2.a.json", "_text-newlines2.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_newlines_3";
run_ok(
    name => $test,
    cmd => [ @cmd, "_text-newlines2.b.json", "_text-newlines2.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_utf8";
run_ok(
    name => $test,
    cmd => [ @cmd, "_text-utf8.a.json", "_text-utf8.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test, { encoding => 'UTF-8' }) },
    exit => 8,
);

$test = "term_text_vs_number";
run_ok(
    name => $test,
    cmd => [ @cmd, "$test.a.json", "$test.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_vs_empty_string";
run_ok(
    name => $test,
    cmd => [ @cmd, "$test.a.json", "$test.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_vs_ref";
run_ok(
    name => $test,
    cmd => [ @cmd, "$test.a.json", "$test.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_vs_undef_0";
run_ok(
    name => $test,
    cmd => [ @cmd, "term_text_vs_undef.a.json", "term_text_vs_undef.b.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

$test = "term_text_vs_undef_1";
run_ok(
    name => $test,
    cmd => [ @cmd, "term_text_vs_undef.b.json", "term_text_vs_undef.a.json" ],
    stdout => sub { file_contents_eq_or_diff("$test.exp", shift, $test) },
    exit => 8,
);

