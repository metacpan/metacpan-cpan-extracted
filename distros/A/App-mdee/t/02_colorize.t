use strict;
use warnings;
use Test::More;
use open qw(:std :encoding(utf-8));

use lib '.';
use t::Util;

# Test that module loads
use_ok('App::Greple::md');

my $test_md = 't/test.md';

SKIP: {
    skip "$test_md not found", 12 unless -f $test_md;

    # Basic output test
    my $r = run("-Mmd $test_md");
    my $out = $r->stdout;
    ok(length($out) > 0, "greple -Mmd produces output");

    # Output should contain ANSI escape sequences
    like($out, qr/\e\[/, "output contains ANSI color sequences");

    # Dark mode should also work
    my $dark = run("'-Mmd::config(mode=dark)' $test_md")->stdout;
    ok(length($dark) > 0, "dark mode produces output");
    like($dark, qr/\e\[/, "dark mode contains ANSI sequences");

    # --cm override should work
    my $override = run("-Mmd --cm h1=RD -- $test_md")->stdout;
    ok(length($override) > 0, "--cm override produces output");

    # OSC 8 test: output should contain OSC 8 sequences for links
    like($out, qr/\e\]8;;/, "output contains OSC 8 hyperlink sequences");

    # ;sub{...} text transformation (hashed theme)
    my $hashed = run("-Mmd --cm 'h3=RD;sub{s/(?<!#)\$/ ###/r}' -- $test_md")->stdout;
    my $strip = sub { local $_ = shift; s/\e\[[0-9;]*[mK]//g; $_ };
    my ($h3_line) = map { $strip->($_) } grep { /Heading 3/ } split /\n/, $hashed;
    like($h3_line, qr/### Heading 3 ###/, "sub{} appends closing hashes to h3");
    my ($h4_line) = map { $strip->($_) } grep { /Heading 4/ } split /\n/, $hashed;
    unlike($h4_line, qr/####$/, "sub{} on h3 does not affect h4");

    # Empty ;sub{} suffix should not break colorization
    my $no_sub = run("-Mmd --cm 'h3=RD' -- $test_md")->stdout;
    my ($h3_plain) = map { $strip->($_) } grep { /Heading 3/ } split /\n/, $no_sub;
    unlike($h3_plain, qr/### Heading 3 ###/, "no sub{} means no closing hashes");

    # Multi-backtick code span: spaces should be stripped (CommonMark)
    my ($multi_bt) = map { $strip->($_) } grep { /Multi-backtick/ } split /\n/, $out;
    like($multi_bt, qr/\`\`\*\*\`\N{ACUTE ACCENT}/, "multi-backtick strips spaces around content");
    unlike($multi_bt, qr/\` \`\*\*\`\N{ACUTE ACCENT} \`/, "multi-backtick does not preserve inner spaces");

    # Code span protection: bold/strike not processed inside code spans
    my ($code_prot) = grep { /inline code with/ } split /\n/, $out;
    unlike($code_prot, qr/\e\[1m/, "bold not applied inside inline code");

    # Word boundary: underscore emphasis not applied inside words (CommonMark)
    my ($wb_line) = map { $strip->($_) } grep { /Word boundaries/ } split /\n/, $out;
    like($wb_line, qr/abc_def_ghi/, "_ not applied inside word abc_def_ghi");
    like($wb_line, qr/foo__bar__baz/, "__ not applied inside word foo__bar__baz");
    like($wb_line, qr/x___y___z/, "___ not applied inside word x___y___z");
}

# Closing code fence: the same character, at least as long (CommonMark)
{
    use File::Temp qw(tempfile);
    my ($fh, $file) = tempfile(SUFFIX => '.md', UNLINK => 1);
    print $fh "```\ncode A\n````\n\nText with **bold** here.\n\n"
            . "```\n```sh\ncode B\n```\n";
    close $fh;
    my @lines = split /\n/, run("-Mmd $file")->stdout;
    my ($text) = grep { /Text with/ } @lines;
    like($text, qr/\e\[[0-9;]*1[;m]/, "a longer closing fence closes the block");
    my ($inner) = grep { /```sh/ } @lines;
    like($inner, qr/\e\[[0-9;]*48;/, "```sh inside a ``` block is code, not a fence");
}

# ATX headings: empty headings and up to 3 spaces of indentation (CommonMark)
{
    use File::Temp qw(tempfile);
    my ($fh, $file) = tempfile(SUFFIX => '.md', UNLINK => 1);
    print $fh "#\n\n##\n\n   # indented\n\n    # four spaces\n\n#foo\n\n####### seven\n";
    close $fh;
    my @lines = split /\n/, run("-Mmd $file")->stdout;
    my $colored = sub { my $re = shift; my ($l) = grep { /$re/ } @lines; $l =~ /\e\[/ };
    ok($colored->(qr/^(?:\e\[[0-9;]*[mK])+#\e/), "'#' alone is an empty h1");
    ok($colored->(qr/##/),              "'##' alone is an empty h2");
    ok($colored->(qr/# indented/),      "a heading indented by 3 spaces");
    ok(!$colored->(qr/# four spaces/),  "4 spaces of indentation is not a heading");
    ok(!$colored->(qr/#foo/),           "'#foo' is not a heading");
    ok(!$colored->(qr/####### seven/),  "7 '#' is not a heading");
}

done_testing;
