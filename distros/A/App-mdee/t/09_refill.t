use strict;
use warnings;
use utf8;
use Test::More;
use open qw(:std :encoding(utf-8));
use Text::ANSI::Fold::Util qw(ansi_width);
use File::Temp qw(tempfile tempdir);

use lib '.';
use t::Util;

# refill=1 joins the lines that pandoc reports as one paragraph (list
# item, quote, definition) and leaves everything else as written.  The
# joined lines are folded when fold is on.  Needs pandoc with the
# sourcepos extension.

# The paragraph positions come from the CommonMark module (libcmark) or
# from pandoc; the tests run with each one that is available.
use App::Greple::md::Blocks qw(available);
my @parsers = available();
@parsers or plan skip_all => 'neither the CommonMark module nor pandoc with sourcepos is available';

$ENV{HOME} = tempdir(CLEANUP => 1);

sub md_file {
    my $text = shift;
    my($fh, $md) = tempfile(SUFFIX => '.md', UNLINK => 1);
    binmode $fh, ":encoding(utf-8)";
    print $fh $text;
    close $fh;
    $md;
}

sub plain {
    my $out = shift;
    $out =~ s/\e\[[0-9;]*[mK]//g;
    $out;
}

sub max_width {
    my $max = 0;
    for (split /\n/, plain(shift)) {
        s/\h+$//;  # a space at the fold point runs in
        my $w = ansi_width($_);
        $max = $w if $w > $max;
    }
    $max;
}

my $input = <<'EOF';
---
title: Front
date: 2026-11-01
---

# Heading

para line one
para line two

- tight a
  tight b
lazy c

> quote a
> quote b

Term
: definition a
  definition b

| A | B |
|---|---|
| 1 | 2 |

```
code a
code b
```

日本語の
段落。

intro to code
```
code c
```
# Heading Two
before table
| C | D |
|---|---|
| 3 | 4 |
after table
EOF

my $joined = <<'EOF';
---
title: Front
date: 2026-11-01
---

# Heading

para line one para line two

- tight a tight b lazy c

> quote a quote b

Term
: definition a definition b

| A | B |
|---|---|
| 1 | 2 |

```
code a
code b
```

日本語の段落。

intro to code
```
code c
```
# Heading Two
before table
| C | D |
|---|---|
| 3 | 4 |
after table
EOF

my $md = md_file($input);

my $toml = md_file(qq(+++\ntitle = "x"\n+++\n\npara a\npara b\n));

for my $parser (@parsers) {
note "refill_parser=$parser";
my $config = "refill=1,refill_parser=$parser";

subtest 'join paragraphs' => sub {
    my $out = run("'-Mmd::config(colorize=0,table=0,$config)' $md")->stdout;
    is(plain($out), $joined, 'paragraph, list item, quote, definition are joined; the rest is as written');
    $out = run("'-Mmd::config(colorize=0,table=0)' $md")->stdout;
    is(plain($out), $input, 'refill=0 leaves the text as it is');
    $out = run("'-Mmd::config(colorize=0,table=0,$config)' $toml")->stdout;
    is(plain($out), qq(+++\ntitle = "x"\n+++\n\npara a para b\n), 'TOML front matter is left as it is');
};

my $sentence = 'the quick brown fox jumps over the lazy dog and runs away';  # 58 chars
my $item = "- $sentence $sentence";
my $fold_md = md_file(join "\n", "# Fold", '', ($sentence) x 3, '', $item, '', "> $sentence", "> $sentence", '', ($sentence) x 2, '');

subtest 'fold joined lines' => sub {
    my $out = run("'-Mmd::config(colorize=0,$config,fold=1,fold_width=40)' $fold_md")->stdout;
    cmp_ok(max_width($out), '<=', 40, 'joined paragraph is folded to the fold width');
    my @quick = plain($out) =~ /\bquick\b/g;
    is(scalar @quick, 9, 'every line appears once in the output');
    my @indented = plain($out) =~ /^  \S/mg;
    is(scalar @indented, 3, 'only the continuation lines of the list item are indented with spaces');
    my @quoted = plain($out) =~ /^> \S/mg;
    is(scalar @quoted, 4, 'the quote and its continuation lines all start with the quote marker');
    like(plain($out), qr/^- the quick.*\n  lazy dog/m, 'continuation lines of a list item are indented');
    like(plain($out), qr/^> the quick.*\n> lazy dog/m, 'continuation lines of a quote repeat the quote marker');
    $out = run("'-Mmd::config(colorize=0,$config,fold=0)' $fold_md")->stdout;
    like(plain($out), qr/^(?:$sentence ){2}$sentence$/m, 'without fold the joined paragraph is one line');
    $out = run("'-Mmd::config($config,fold=1,fold_width=40)' $fold_md")->stdout;
    like(plain($out), qr/^> the quick.*\n> lazy dog/m, 'quote continuation lines repeat the marker with colorize on');
    like(plain($out), qr/^- the quick.*\n  lazy dog/m, 'list continuation lines are indented with colorize on');
};

subtest 'two files' => sub {
    my $one = plain(run("'-Mmd::config(colorize=0,$config,fold=1,fold_width=40)' -h $fold_md")->stdout);
    my $two = plain(run("'-Mmd::config(colorize=0,$config,fold=1,fold_width=40)' -h $fold_md $fold_md")->stdout);
    $two =~ s/\f//g;
    is($two, $one x 2, 'the second file is refilled like the first');
};

my $cell = 'alpha beta gamma delta epsilon zeta eta theta iota kappa lambda';  # wider than 40
my $table_md = md_file(<<"EOF");
| Name | Description |
|------|-------------|
| one  | $cell |
| two  | short |

$sentence
$sentence
EOF

my $tight_md = md_file(<<"EOF");
before table
| Name | Description |
|------|-------------|
| one  | $cell |
| two  | short |
$sentence
$sentence
EOF

for my $style ('', ',table_style=3line', ',table_style=simple') {
    subtest "paragraph below a wrapped table$style" => sub {
        my $out = plain(run("'-Mmd::config(colorize=0,$config,fold=1,fold_width=40,table_width=40$style)' $table_md")->stdout);
        cmp_ok(max_width($out), '<=', 40, 'paragraph below the table is folded');
        my @one = $out =~ /\bone\b/g;
        is(scalar @one, 1, 'table rows appear once');
        my @quick = $out =~ /\bquick\b/g;
        is(scalar @quick, 2, 'paragraph lines appear once');
    };
    subtest "paragraph right below a wrapped table$style" => sub {
        my $out = plain(run("'-Mmd::config(colorize=0,$config,fold=1,fold_width=40,table_width=40$style)' $tight_md")->stdout);
        cmp_ok(max_width($out), '<=', 40, 'paragraph right below the table is folded');
        my @one = $out =~ /\bone\b/g;
        is(scalar @one, 1, 'table rows appear once');
        like($out, qr/^before table$/m, 'the line before the table stays');
    };
}

}

done_testing;
