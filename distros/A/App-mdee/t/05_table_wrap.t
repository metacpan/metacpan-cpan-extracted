use strict;
use warnings;
use utf8;
use Test::More;
use open qw(:std :encoding(utf-8));
use Text::ANSI::Fold::Util qw(ansi_width);

use lib '.';
use t::Util;

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
my $marked_fold = run("'-Mmd::config(colorize=0,table=1,rule=1,foldlist=1,foldwidth=40,table_width=40,table_wrap_mark=+)' $md")->stdout;
is(join("\n", table_lines($marked_fold)), join("\n", @m), 'marked table rows are not re-folded by ansifold');

# table_cell_mark marks the first line of every cell (default: none)
unlike($wrapped, qr/^\+/m, 'no cell mark by default');
my $item = run("'-Mmd::config(colorize=0,table=1,rule=1,table_width=40,table_cell_mark=+)' $md")->stdout;
my @i = table_lines($item);
is(scalar(grep { /^\+/ } @i), scalar(grep { /^ \S/ } @w), 'every row start is marked');
ok((grep { /^\+\S*\s*$V\+/ } @i), 'cells in the second column are marked too');
ok(!(grep { /^\s/ && /\+/ } @i), 'continuation lines carry no cell mark');
is($item =~ s/\+/ /gr, $wrapped, 'the cell mark takes the place of one pad space');
my $item_fold = run("'-Mmd::config(colorize=0,table=1,rule=1,foldlist=1,foldwidth=40,table_width=40,table_cell_mark=+)' $md")->stdout;
is(join("\n", table_lines($item_fold)), join("\n", @i), 'cell-marked table rows are not re-folded by ansifold');
my $item_notrim = run("'-Mmd::config(colorize=0,table=1,rule=1,table_trim=0,table_width=40,table_cell_mark=+)' $md")->stdout;
like($item_notrim, qr/^$V\+key/m, 'non-trim: the mark follows the left border');
like($item_notrim, qr/^\x{251C}\x{2500}+\x{253C}\x{2500}+\x{2524}$/m, 'non-trim: the separator row is still converted to rules');
is(scalar(grep { /\+\s*$/ } table_lines($item_notrim)), 0, 'non-trim: the empty border column is not marked');

# ansifold must not re-fold formatted table rows (TABLE exclude pattern)
my $folded = run("'-Mmd::config(colorize=0,table=1,rule=1,foldlist=1,foldwidth=40,table_width=200)' $md")->stdout;
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

done_testing;
