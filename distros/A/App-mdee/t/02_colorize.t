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

# * and ** need a left-flanking opener and a right-flanking closer
# (CommonMark); cjk_friendly=1 takes the markdown-cjk-friendly rules
{
    use File::Temp qw(tempfile);
    my ($fh, $file) = tempfile(SUFFIX => '.md', UNLINK => 1);
    binmode $fh, ':encoding(utf-8)';
    # key, text, italic (\e[3m) or bold (\e[1m), CommonMark, cjk_friendly
    my @cases = (
        [ A => 'L*=50, a*=68, b*=48',                   3, 0, 0, "an opener after a letter and before '='" ],
        [ B => 'x *foo* y',                             3, 1, 1, "*foo*" ],
        [ C => '2*3*4',                                 3, 1, 1, "* inside a word" ],
        [ D => 'x * foo * y',                           3, 0, 0, "an opener before a space" ],
        [ E => 'x *"foo"* y',                           3, 1, 1, "*\"foo\"* after a space" ],
        [ F => 'a*"foo"*b',                             3, 0, 0, "*\"foo\"* between letters" ],
        [ G => 'x *foo *y',                             3, 0, 0, "a closer after a space" ],
        [ H => "x *foo\x{3002}* y",                     3, 1, 1, "a closer after a fullwidth period and before a space" ],
        [ I => "\x{65e5}*\x{300c}foo\x{300d}*\x{3067}", 3, 0, 1, "Japanese: *\x{300c}...\x{300d}* between kanji and kana" ],
        [ J => "\x{65e5}*foo\x{3002}*\x{3067}",         3, 0, 1, "Japanese: a closer after a fullwidth period" ],
        [ K => 'L**=50, a**=68',                        1, 0, 0, "** after a letter and before '='" ],
        [ L => 'x **foo** y',                           1, 1, 1, "**foo**" ],
        [ M => "\x{65e5}**\x{300c}foo\x{300d}**\x{3067}", 1, 0, 1, "Japanese: **\x{300c}...\x{300d}** between kanji and kana" ],
        [ N => "\x{65e5}**foo\x{3002}**\x{3067}",       1, 0, 1, "Japanese: ** after a fullwidth period" ],
        [ O => "x **[link](#u)**\x{3082}",              1, 0, 1, "** after a link and before kana" ],
        [ P => 'x **`code`**y',                         1, 0, 0, "** after code and before a letter" ],
        [ Q => 'x **[link](#u)** y',                    1, 1, 1, "** around a link" ],
        [ R => 'x **a#**b**c',                          1, 1, 1, "** closes the nearest opener" ],
    );
    print $fh map { "$_->[0]: $_->[1]\n\n" } @cases;
    close $fh;
    for my $mode ([ CommonMark => '-Mmd' ], [ cjk_friendly => "'-Mmd::config(cjk_friendly=1)'" ]) {
        my($name, $module) = @$mode;
        my @lines = split /\n/, run("$module $file")->stdout;
        my $i = $name eq 'CommonMark' ? 3 : 4;
        for (@cases) {
            my($key, $sgr, $want, $desc) = @{$_}[0, 2, $i, 5];
            my ($l) = grep { /^\Q$key\E:/ } @lines;
            my $got = $l =~ /\e\[${sgr}m/ ? 1 : 0;
            is($got, $want, "$name: $desc" . ($want ? "" : " does not count"));
        }
        # the ** after "#" can only open, and pairs with the next one
        my ($r) = map { s/\e\[1m/</gr =~ s/\e\[[\d;]*[mK]//gr } grep { /^R:/ } @lines;
        like($r, qr/\*\*a#\*\*<b\*\*c/, "$name: only b is bold in **a#**b**c");
    }
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

# h4 and h5 are bold with an underline, h6 is bold
{
    my $out = run("-Mmd t/test.md")->stdout;
    like($out, qr/\e\[[\d;]*;4;1m#### /, "h4 has an underline");
    like($out, qr/\e\[[\d;]*;4;1m##### /, "h5 has an underline");
    like($out, qr/\e\[[\d;]*;1m###### /, "h6 has none");
    unlike($out, qr/4:2/, "no double underline without the theme");
}

done_testing;
