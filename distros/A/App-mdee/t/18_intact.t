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
# --intact.  The joined table is not folded as text.

my $US = "\x1F";
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
my $rows = join "\n", map { split /$US/, $_, -1 } @tables;
my @missing = grep { index($lines, "$_\n") < 0 } split /\n/, $rows;
is(scalar @missing, 0, 'every row is a line of the table without intact');
unlike($intact, qr/$US\n|\n$US|$US$US/, 'US goes only between rows');

# the text around the tables is the same
(my $joined = $intact) =~ s/$US/\n/g;
is($joined, $lines, 'the rest of the text is not changed');

done_testing;
