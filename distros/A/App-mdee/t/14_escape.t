use v5.14;
use warnings;
use utf8;
use open qw(:std :encoding(utf-8));
use Test::More;
use File::Temp qw(tempfile);

use lib '.';
use t::Util;

use_ok('App::Greple::md');

# remove_controls: what a file must not send to the terminal
sub removed {
    local $_ = shift;
    App::Greple::md::remove_controls();
    $_;
}

my @cases = (
    [ 'plain text',          "a b\n",                     "a b\n" ],
    [ 'tab, cr, ff',         "a\tb\r\n\fc\n",             "a\tb\r\n\fc\n" ],
    [ 'japanese',            "日本語\n",                  "日本語\n" ],
    [ 'a color stays',       "\e[31mred\e[m\n",           "\e[31mred\e[m\n" ],
    [ '256 and rgb stay',    "\e[38;5;1mx\e[38;2;1;2;3my\e[m\n", "\e[38;5;1mx\e[38;2;1;2;3my\e[m\n" ],
    [ 'title with BEL',      "a\e]0;T\ab\n",              "ab\n" ],
    [ 'title with ST',       "a\e]0;T\e\\b\n",            "ab\n" ],
    [ 'clipboard',           "a\e]52;c;aGk=\e\\b\n",      "ab\n" ],
    [ 'hyperlink',           "\e]8;;http://x\e\\a\e]8;;\e\\\n", "a\n" ],
    [ 'over two lines',      "a\eP1\n2\e\\b\n",           "ab\n" ],
    [ 'not closed',          "a\e]0;T\nb\n",              "a0;T\nb\n" ],
    [ 'clear screen',        "a\e[2Jb\n",                 "ab\n" ],
    [ 'cursor',              "a\e[10;20Hb\e[?25lc\n",     "abc\n" ],
    [ 'other escape',        "a\ecb\e(0c\n",              "abc\n" ],
    [ 'lone escape',         "a\e",                       "a" ],
    [ 'the mark of protect', "\e[256m0\e[m\n",            "0\e[m\n" ],
    [ 'C1 of 8 bits',        "a\x{9d}0;T\x{9c}b\x{9b}2Jc\n", "abc\n" ],
    [ 'C1 color goes too',   "a\x{9b}31mb\n",             "ab\n" ],
    [ 'C1 DCS',              "a\x{90}1\x{9c}b\n",         "ab\n" ],
    [ 'text after 9C stays', "a\e]0;T\x{9c}text\ab\n",    "atextb\n" ],
    [ 'hyperlink with 9C',   "\e]8;;http://x\x{9c}a\e]8;;\x{9c}\n", "a\n" ],
    [ 'DCS with BEL',        "a\eP1\ab\n",                "ab\n" ],
    [ 'APC with ST',         "a\e_1\e\\b\n",              "ab\n" ],
    [ 'DCS with a control',  "a\eP1\x012\e\\b\n",         "a12b\n" ],
    [ 'other controls',      "a\ab\x08c\x0ed\x7f\n",      "abcd\n" ],
);
for (@cases) {
    my($name, $text, $want) = @$_;
    is(removed($text), $want, $name);
}

# through greple
my($fh, $md) = tempfile(SUFFIX => '.md', UNLINK => 1);
binmode $fh, ':encoding(utf-8)';
print $fh "# head\n\nraw \e]0;TITLE\a end \e[2J\n\nmark \e[256m99\e[m end `code`\n\n\e[31mred\e[m\n";
close $fh;

for my $opt ('', 'colorize=0,', 'table=0,') {
    my $r = run("'-Mmd::config(${opt}mode=light)' -- --filter --color=always $md");
    is($r->status, 0, "[$opt] a mark of protect in the text does not stop it");
    my $out = $r->stdout;
    unlike($out, qr/\e\]0;|TITLE/, "[$opt] no title");
    unlike($out, qr/\e\[2J/, "[$opt] no clear screen");
    unlike($out, qr/\e\[256m/, "[$opt] no mark of protect");
    like($out, qr/\e\[31mred\e\[m/, "[$opt] the color stays");
}

done_testing;
