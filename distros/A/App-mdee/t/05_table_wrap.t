use strict;
use warnings;
use utf8;
use Test::More;
use open qw(:std :encoding(utf-8));
use Text::ANSI::Fold::Util qw(ansi_width);

use File::Temp qw(tempdir);

use lib '.';
use t::Util;

# no ~/.ansicolumnrc of the user
$ENV{HOME} = tempdir(CLEANUP => 1);

my $md = 't/table_wrap.md';
my $V = "\x{2502}";   # │
my $strip = sub { local $_ = shift; s/\e\[[0-9;]*[mK]//g; s/\e\]8;;[^\e]*\e\\//g; $_ };
sub table_lines { grep { /[\x{2502}\x{253C}]/ } map { $strip->($_) } split /\n/, shift }

# table_width wraps over-wide columns
my $wrapped = run("'-Mmd::config(colorize=0,table=1,rule=1,table_width=40)' $md")->stdout;
my @w = table_lines($wrapped);
ok(@w > 6, 'rows were wrapped into extra lines');
ok(!(grep { ansi_width($_) > 40 } @w), 'every table line fits in 40 columns');
ok((grep { /^\s+$V/ } @w), 'continuation lines keep the column rule');
is(scalar(grep { /\x{253C}/ } @w), 1, 'exactly one separator row');
unlike($wrapped, qr/^\s*[。、]/m, 'no line starts with Japanese closing punctuation');

my $plain = run("'-Mmd::config(colorize=0,table=1,rule=1)' $md")->stdout;
ok((grep { ansi_width($_) > 40 } table_lines($plain)), 'without table_width the table is wider than 40');
is(run("'-Mmd::config(colorize=0,table=1,rule=1,table_width=200)' $md")->stdout, $plain,
   'a fitting width leaves output unchanged');

# table_cell caps a column (colon separated)
my $cell = run("'-Mmd::config(colorize=0,table=1,rule=1,table_cell=0:10)' $md")->stdout;
ok(!(grep { /$V(.*)$/ && ansi_width($1) > 12 } table_lines($cell)),
   'table_cell caps column 2 at 10 (+padding)');

my $notrim = run("'-Mmd::config(colorize=0,table=1,rule=1,table_trim=0,table_cell=0:10)' $md")->stdout;
ok(!(grep { /^\S*$V[^$V]*$V(.*?)$V/ && ansi_width($1) > 12 } table_lines($notrim)),
   'non-trim mode shifts the cell list');

# table_wrap_mark marks continuation lines of wrapped cells (default: none)
unlike($wrapped, qr/\x{203A}|\+/, 'no wrap mark by default');
my $wm = run("'-Mmd::config(colorize=0,table=1,rule=1,table_width=40,table_wrap_mark=+)' $md")->stdout;
my @m = table_lines($wm);
ok((grep { /$V\+\S/ } @m), 'continuation lines start with the wrap mark');
ok(!(grep { /^\s*\+/ } @m), 'the mark replaces the pad, so no line starts with it when column 1 fits');
is($wm =~ s/\+/ /gr, $wrapped, 'the mark takes the place of one pad space');
my $marked_fold = run("'-Mmd::config(colorize=0,table=1,rule=1,fold=1,fold_width=40,table_width=40,table_wrap_mark=+)' $md")->stdout;
is(join("\n", table_lines($marked_fold)), join("\n", @m), 'marked table rows are not re-folded by ansifold');

# table_cell_mark marks the first line of the cells in a wrapped column,
# on the body rows only (default: none)
unlike($wrapped, qr/\+/, 'no cell mark by default');
my $item = run("'-Mmd::config(colorize=0,table=1,rule=1,table_width=40,table_cell_mark=+)' $md")->stdout;
my @i = table_lines($item);
is(scalar(grep { /$V\+/ } @i), 4, 'every body row is marked in the wrapped column');
unlike($item, qr/^\+/m, 'the first column, which did not wrap, is not marked');
like($i[0], qr/^ key\s+$V description/, 'the header row is not marked');
ok(!(grep { /^\s+$V/ && /\+/ } @i), 'continuation lines carry no cell mark');
is($item =~ s/\+/ /gr, $wrapped, 'the cell mark takes the place of one pad space');
my $item_fold = run("'-Mmd::config(colorize=0,table=1,rule=1,fold=1,fold_width=40,table_width=40,table_cell_mark=+)' $md")->stdout;
is(join("\n", table_lines($item_fold)), join("\n", @i), 'cell-marked table rows are not re-folded by ansifold');
my $item_notrim = run("'-Mmd::config(colorize=0,table=1,rule=1,table_trim=0,table_width=40,table_cell_mark=+)' $md")->stdout;
like($item_notrim, qr/^$V key\s+$V description/m, 'non-trim: the header row is not marked');
like($item_notrim, qr/^$V k1\s+$V\+the quick/m, 'non-trim: the mark follows the column border');
like($item_notrim, qr/^\x{251C}\x{2500}+\x{253C}\x{2500}+\x{2524}$/m, 'non-trim: the separator row is still converted to rules');
is(scalar(grep { /\+\s*$/ } table_lines($item_notrim)), 0, 'non-trim: the empty border column is not marked');

# ansifold must not re-fold formatted table rows (TABLE exclude pattern)
my $folded = run("'-Mmd::config(colorize=0,table=1,rule=1,fold=1,fold_width=40,table_width=200)' $md")->stdout;
my @f = map { $strip->($_) } split /\n/, $folded;
my ($start) = grep { $f[$_] =~ /key.*description/ } 0..$#f;
my ($end)   = grep { $f[$_] =~ /^\s*k2\s/ } 0..$#f;
is($end - $start, 5, 'table rows are not re-folded by ansifold (header, rule, 4 rows)');
ok(!(grep { !/[\x{2502}\x{253C}]/ } @f[$start..$end]), 'every table line keeps its rule character');

# list items containing | must still be folded (not mistaken for a table)
my @list = grep { /grep foo|wc -l|cat a/ } @f;
ok(@list == 3, 'fixture has three pipe-containing list items');
my ($l1) = grep { $f[$_] =~ /grep foo/ } 0..$#f;
like($f[$l1 + 1], qr/^\h+\S/, 'pipe-containing list items are folded by ansifold');

# how cells are wrapped is given by the table_* parameters, not by
# the user's ~/.ansicolumnrc
my $boundary = run("'-Mmd::config(colorize=0,table=1,rule=1,table_width=40,table_boundary=none,table_linebreak=none)' $md")->stdout;
isnt($boundary, $wrapped, 'table_boundary and table_linebreak change the wrapping');
{
    my $home = tempdir(CLEANUP => 1);
    open my $fh, '>', "$home/.ansicolumnrc" or die;
    print $fh "option default --runin=0 --runout=0 --boundary=none --linebreak=none\n";
    close $fh;
    local $ENV{HOME} = $home;
    my $rc = run("'-Mmd::config(colorize=0,table=1,rule=1,table_width=40)' $md")->stdout;
    is($rc, $wrapped, '~/.ansicolumnrc does not change the wrapping');
}

# with table_gap=2, the pad at the right end of a table goes when the table does not fit
# the width with it (ansicolumn 1.70), in every style
{
    my $dir = tempdir(CLEANUP => 1);
    my $file = "$dir/tight.md";
    open my $fh, '>', $file or die;
    print $fh "| 名前 | 説明 |\n|------|------|\n",
        "| 乙 | 句読点のある文章は、行の終わりに、追い込まれることがあります。それを見ます。 |\n";
    close $fh;
    for my $style (qw(lattice:table_gap=2 3line:table_gap=2 simple:table_gap=2)) {
        my $param = "table_style=" . $style =~ tr/:/,/r;
        my $out = sub {
            my $w = shift;
            my $o = run("'-Mmd::config(colorize=0,table=1,rule=1,$param,table_width=$w)' $file")->stdout;
            map { $strip->($_) } split /\n/, $o;
        };
        my @l40 = $out->(40);
        is_deeply([ map { ansi_width($_) } @l40 ], [ (40) x @l40 ], "$style: 40 wide in the width 40");
        ok((grep { /あります。$/ } @l40), "$style: a character run in is at the right end");
        my @l41 = $out->(41);
        is_deeply([ map { ansi_width($_) } @l41 ], [ (41) x @l41 ], "$style: 41 wide in the width 41");
        ok((grep { /あります。 $/ } @l41), "$style: the pad stays when the table fits with it");
        my @text = map { [ map { s/\s+$//r } grep { /\p{Hiragana}/ } @$_ ] } \@l40, \@l41;
        is_deeply($text[0], $text[1],
                  "$style: the lines are broken at the same places");
    }

    # 3line and simple have no space at the right of a cell: table_gap
    # is the number of spaces to the mark of the next column
    my $gap = "$dir/gap.md";
    open $fh, '>', $gap or die;
    print $fh "| a | b | c |\n|---|---|---|\n| xx | yyy | z |\n| xx | the quick brown fox jumps | z |\n";
    close $fh;
    my $row = sub {
        my $o = run("'-Mmd::config(colorize=0,table=1,rule=1,@_)' $gap")->stdout;
        grep { /xx/ } map { $strip->($_) } split /\n/, $o;
    };
    for my $style (qw(3line simple)) {
        is(($row->("table_style=$style"))[1], ' xx  the quick brown fox jumps  z',
           "$style: no space at the right of a cell");
        like(($row->("table_style=$style,table_cell_mark=+,table_width=20"))[0] // "", qr{^ xx \+\S},
           "$style: one space before the mark of the next column");
        is(($row->("table_style=$style,table_gap=2"))[1], ' xx   the quick brown fox jumps   z ',
           "$style: table_gap=2");
    }
    is(($row->(""))[1], " xx$V the quick brown fox jumps$V z", 'lattice: no space at the right of a cell');
    is(($row->("table_gap=2"))[1], " xx $V the quick brown fox jumps $V z ", 'lattice: table_gap=2');
}

done_testing;
