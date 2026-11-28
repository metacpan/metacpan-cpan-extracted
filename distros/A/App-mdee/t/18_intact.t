use strict;
use warnings;
use utf8;
use Test::More;
use open qw(:std :encoding(utf-8));

use File::Temp qw(tempdir);

use lib '.';
use t::Util;

# no ~/.ansicolumnrc of the user
$ENV{HOME} = tempdir(CLEANUP => 1);

# intact=table: the lines of a formatted table are joined into one line
# by UNIT SEPARATOR (0x1F), the last newline kept, for ansicolumn
# --intact.  The joined table is not folded as text.  The lines of a
# row are joined by GROUP SEPARATOR (0x1D) instead, and so are the
# header, the rule below it and the first row, so that a pane does not
# end inside them.

my $US = "\x1F";
my $GS = "\x1D";
my $md = 't/table_wrap.md';
my $strip = sub { local $_ = shift; s/\e\[[0-9;]*[mK]//g; s/\e\]8;;[^\e]*\e\\//g; $_ };
my $cfg = 'colorize=0,table=1,rule=1,table_width=40,fold=1,fold_width=30';

my $lines  = $strip->(run("'-Mmd::config($cfg)' $md")->stdout);
my $intact = $strip->(run("'-Mmd::config($cfg,intact=table)' $md")->stdout);

unlike($lines, qr/$US/, 'without intact, no UNIT SEPARATOR');
like($intact, qr/$US/, 'with intact, the rows are joined');

# the rows of every table are the lines without intact
my @tables = grep { /$US/ } split /\n/, $intact;
is(scalar @tables, 1, 'the table is one line');
my $rows = join "\n", map { split /[$US$GS]/, $_, -1 } @tables;
my @missing = grep { index($lines, "$_\n") < 0 } split /\n/, $rows;
is(scalar @missing, 0, 'every row is a line of the table without intact');
unlike($intact, qr/[$US$GS]\n|\n[$US$GS]|[$US$GS]{2}/, 'US and GS go only between lines');

# the units divided by US: the header with the rule and the first row,
# whose cell is wrapped, then the other rows, each with its lines
my @units = split /$US/, $tables[0];
is(scalar @units, 4, 'a unit for the head and one for each other row');
my @head = split /$GS/, $units[0];
like($head[0], qr/^ key/, 'the head: the header');
like($head[1], qr/^\x{2500}+\x{253C}/, 'the head: the rule');
like($head[2], qr/k1/, 'the head: the first row');
ok(@head > 3, 'the head: all the lines of the first row');
like($units[1], qr/alpha[^$GS]*$GS/, 'a wrapped row is a group');
like($units[3], qr/^[^$GS]*k2[^$GS]*$/, 'a row of one line is a line');

# the text around the tables is the same
(my $joined = $intact) =~ s/[$US$GS]/\n/g;
is($joined, $lines, 'the rest of the text is not changed');

# 3line: the rule above goes with the head, the one below with the last
# row, and the rules are as wide as the table
{
    my $cfg = "$cfg,table_style=3line";
    my $intact = $strip->(run("'-Mmd::config($cfg,intact=table)' $md")->stdout);
    my($table) = grep { /$US/ } split /\n/, $intact;
    my @units = split /$US/, $table;
    my @head = split /$GS/, $units[0];
    like($head[0], qr/^\x{2500}+$/, '3line: the rule above in the head');
    like($head[1], qr/^ key/, '3line: then the header');
    like($units[-1], qr/k2[^$GS]*$GS\x{2500}+$/, '3line: the rule below with the last row');
    is(length $head[0], length $head[1], '3line: the rule is as wide as the header');
}

# keep.table: what is joined by GS, kept in one pane
{
    my $units = sub {
	my $cfg = shift;
	my $out = $strip->(run("'-Mmd::config($cfg,intact=table)' $md")->stdout);
	my($table) = grep { /[$US$GS]/ } split /\n/, $out;
	[ map { [ split /$GS/ ] } split /$US/, $table ];
    };
    my $none = $units->("$cfg,keep.table=none");
    ok(!(grep { @$_ > 1 } @$none), 'none: no group');
    like($none->[0][0], qr/^ key/, 'none: the header alone');

    my $row = $units->("$cfg,keep.table=row");
    like($row->[0][0], qr/^ key/, 'row: the header alone');
    is(scalar @{$row->[0]}, 1, 'row: the header is not a group');
    like($row->[1][0], qr/^\x{2500}+\x{253C}/, 'row: the rule alone');
    like($row->[2][0], qr/k1/, 'row: the first row');
    ok(@{$row->[2]} > 1, 'row: a wrapped row is a group');

    my $head = $units->("$cfg,keep.table=head");
    is_deeply($head, $units->($cfg), 'head is the default');
    is(scalar @$head, 4, 'head: the header with the first row, and the other rows');

    my $all = $units->("$cfg,keep.table=all");
    is(scalar @$all, 1, 'all: the table is one group');

    my $r = run("'-Mmd::config($cfg,intact=table,keep.table=header)' $md");
    isnt($r->status, 0, 'an unknown value dies');

    # 3line: the rule below goes with the last row only with head
    my $row3 = $units->("$cfg,table_style=3line,keep.table=row");
    like($row3->[-1][0], qr/^\x{2500}+$/, '3line row: the rule below alone');
    my $head3 = $units->("$cfg,table_style=3line,keep.table=head");
    like($head3->[-1][-1], qr/^\x{2500}+$/, '3line head: the rule below with the last row');
    ok(@{$head3->[-1]} > 1, '3line head: the last row is a group');
}

# a table of one row is a group with no US, and is not folded as text
{
    my $dir = tempdir(CLEANUP => 1);
    my $one = "$dir/one.md";
    open my $fh, '>:utf8', $one or die;
    print $fh "| - key | description |\n|-----|-------------|\n| k1 | the quick brown fox jumps over the lazy dog and keeps on running |\n";
    close $fh;
    my $intact = $strip->(run("'-Mmd::config($cfg,intact=table)' $one")->stdout);
    my @lines = split /\n/, $intact;
    is(scalar @lines, 1, 'one row: one line');
    unlike($intact, qr/$US/, 'one row: no US');
    like($intact, qr/$GS/, 'one row: a group');
    like($intact, qr/^ - key\s*\x{2502} description/, 'one row: the header is not folded');
}

# with refill, a parser may take a table for a paragraph (libcmark has
# no tables): the lines of the table, joined into one, are not regions
# to fold
SKIP: {
    require App::Greple::md::Blocks;
    my @parsers = App::Greple::md::Blocks::available();
    skip 'no parser for refill', 2 unless @parsers;
    my $dir = tempdir(CLEANUP => 1);
    my $file = "$dir/refill.md";
    open my $fh, '>:utf8', $file or die;
    print $fh "# h\n\nparagraph\n\n| a | b |\n| - | - |\n| c | d |\n| e | f |\n| g | h |\n";
    close $fh;
    for my $parser ($parsers[0]) {
        my $r = run("'-Mmd::config($cfg,intact=table,refill=1,refill_parser=$parser)' $file");
        is($r->status, 0, "refill with $parser: no error");
        like($strip->($r->stdout), qr/ c\x{2502} d$US e/, "refill with $parser: the table");
    }
}

done_testing;
