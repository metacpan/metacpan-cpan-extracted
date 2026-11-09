use v5.14;
use warnings;
use utf8;
use open qw(:std :encoding(utf-8));
use Test::More;
use File::Temp qw(tempfile);
use Text::ANSI::Fold::Util qw(ansi_width);

use lib '.';
use t::Util;

use_ok('App::Greple::md::widen');
sub widen {
    my($text, $spec) = @_;
    local $_ = $text;
    App::Greple::md::widen::widen(chars => $spec);
    $_;
}

my $N = "\x{a0}";

# widen: a no-break space after each character
my @cases = (
    [ 'after a circled digit', "a①b\n",          '2460-24FF', "a①${N}b\n" ],
    [ 'at the end of a line',  "a①\nb②\n",       '2460-24FF', "a①$N\nb②$N\n" ],
    [ 'several',               "①②③\n",          '2460-24FF', "①$N②$N③$N\n" ],
    [ 'space follows',         "① a\n",          '2460-24FF', "①${N} a\n" ],
    [ 'no-break space follows', "①${N}a\n",      '2460-24FF', "①${N}a\n" ],
    [ 'twice is the same',     "a①${N}b\n",      '2460-24FF', "a①${N}b\n" ],
    [ 'other characters',      "→○abc\n",        '2460-24FF', "→○abc\n" ],
    [ 'code span',             "`①` ①\n",        '2460-24FF', "`①` ①$N\n" ],
    [ 'double backticks',      "`` ① ` `` ①\n",  '2460-24FF', "`` ① ` `` ①$N\n" ],
    [ 'code with a language',  "①\n```perl\n①\n```\n①\n", '2460-24FF', "①$N\n```perl\n①\n```\n①$N\n" ],
    [ 'language after a space', "``` perl\n①\n```\n", '2460-24FF', "``` perl\n①\n```\n" ],
    [ 'code without a language', "①\n```\n①\n```\n①\n", '2460-24FF', "①$N\n```\n①$N\n```\n①$N\n" ],
    [ 'spaces after the fence', "```  \n①\n```\n", '2460-24FF', "```  \n①$N\n```\n" ],
    [ 'code span in a block without a language', "```\n`①` ①\n```\n", '2460-24FF', "```\n`①` ①$N\n```\n" ],
    [ 'block without a language after one with', "```sh\n①\n```\n```\n①\n```\n", '2460-24FF', "```sh\n①\n```\n```\n①$N\n```\n" ],
    [ 'tilde fence',           "~~~sh\n①\n~~~\n",  '2460-24FF', "~~~sh\n①\n~~~\n" ],
    [ 'tilde without a language', "~~~\n①\n~~~\n",  '2460-24FF', "~~~\n①$N\n~~~\n" ],
    [ 'longer closing fence',  "```sh\n①\n`````\n①\n", '2460-24FF', "```sh\n①\n`````\n①$N\n" ],
    [ 'unclosed fence',        "```sh\n①\n",     '2460-24FF', "```sh\n①$N\n" ],
    [ 'link destination',      "[①](http://x/①)\n", '2460-24FF', "[①$N](http://x/①)\n" ],
    [ 'autolink',              "<http://x/①>\n", '2460-24FF', "<http://x/①>\n" ],
    [ 'range',                 "①→\n",           '2192', "①→$N\n" ],
    [ 'ranges',                "①→○\n",          '2190-2199:25CB', "①→$N○$N\n" ],
    [ 'emoji selector',        "a🗑\x{fe0f}b\n",  '1F5D1', "a🗑\x{fe0f}${N}b\n" ],
    [ 'text selector',         "a🗑\x{fe0e}b\n",  '1F5D1', "a🗑\x{fe0e}${N}b\n" ],
    [ 'selector and a space',  "🗑\x{fe0f} a\n",  '1F5D1', "🗑\x{fe0f}${N} a\n" ],
    [ 'selector twice is the same', "🗑\x{fe0f}${N}a\n", '1F5D1', "🗑\x{fe0f}${N}a\n" ],
);
is(widen("a①🗑b\n", undef), "a①$N🗑${N}b\n", 'the default has the wastebasket');
for (@cases) {
    my($name, $text, $spec, $want) = @$_;
    is(widen($text, $spec), $want, $name);
}
ok(!eval { widen("a\n", 'x'); 1 }, 'a bad range dies');
like($@, qr/widen: x/, 'and says what');

# through the md module: the table is aligned, and the character keeps
# its column at the end of a folded line
my($fh, $md) = tempfile(SUFFIX => '.md', UNLINK => 1);
binmode $fh, ':encoding(utf-8)';
print $fh <<'END';
- ①を押して、②を選択し、③で確定します。長い行を折り返すための文章を続けます。

| 番号 | 内容 |
|------|------|
| ①②   | 次に④の説明 |
| abc  | ⑤ |

```perl
①
```
END
close $fh;

sub output {
    my $opt = shift;
    my $out = run("'-Mmd::config(colorize=0,fold=1,fold_width=28,table_width=40)' $opt -- --filter $md")->stdout;
    $out =~ s/\e\[[\d;]*[mK]//gr;
}

my $off = output('');
unlike($off, qr/$N/, 'off by default');

my $out = output(q(--begin '&widen'));
like($out, qr/①$N/, 'the function adds a no-break space');
like($out, qr/^①$/m, 'not in a code block');

my @rows = grep { /\x{2502}/ } split /\n/, $out;
is(scalar @rows, 3, 'the table is formatted');
is(scalar(grep { ansi_width($_) == ansi_width($rows[0]) } @rows), 3, 'all rows have the same width');

$out = output(q(--begin '&widen(chars=2192)'));
unlike($out, qr/①$N/, 'chars replaces the default');

done_testing;
