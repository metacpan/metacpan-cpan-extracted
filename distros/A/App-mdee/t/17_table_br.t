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

# A newer ansicolumn takes a LINE SEPARATOR as a line break in a
# cell; an older one ends the row there
use App::Greple::md;
plan skip_all => 'ansicolumn does not break a cell at LINE SEPARATOR'
    unless App::Greple::md::call_ansicolumn("a\x{2028}b|c\n", '-t', '-s', '|', '-o', '|') eq "a|c\nb|\n";

# A <br> in a cell of a table breaks the cell into lines: the md
# module puts a LINE SEPARATOR (U+2028) after it, which ansicolumn
# takes as a line break in the cell.  The <br> itself is shown.

my $md = 't/table_br.md';
my $V = "\x{2502}";   # │
my $strip = sub { local $_ = shift; s/\e\[[0-9;]*[mK]//g; s/\e\]8;;[^\e]*\e\\//g; $_ };

my $out = $strip->(run("'-Mmd::config(colorize=0,table=1,rule=1)' $md")->stdout);

unlike($out, qr/\x{2028}/, 'no LINE SEPARATOR is left in the output');
like($out, qr/^ k1\h+$V one<br>\h*$/m, 'a cell is broken after <br>, which stays');
like($out, qr/^\h+$V two<BR\/>\h*$/m, '<BR/> breaks a cell');
like($out, qr/^\h+$V three<br \/>\h*$/m, '<br /> breaks a cell');
like($out, qr/^\h+$V four\h*$/m, 'the last line of the cell');
like($out, qr/^ k2\h+$V `x<br>y` and \\<br> z\h*$/m,
     'no break in a code span, nor after an escaped <br>');
like($out, qr/^ k3\h+$V - item<br>\h*\n\h+$V   - nested\h*$/m,
     'the spaces after <br> are kept');
like($out, qr/^Not a table: a<br>b$/m, 'a <br> outside a table is left as it is');
like($out, qr/^\| two \| lines<br>only \|$/m, 'a <br> in lines not formatted as a table');

my $notable = run("'-Mmd::config(colorize=0,table=0)' $md")->stdout;
unlike($notable, qr/\x{2028}/, 'table=0: no LINE SEPARATOR');
like($notable, qr/^\| k1 \| one<br>two<BR\/>three<br \/>four \|$/m, 'table=0: the row as written');

my $color = run("'-Mmd::config(table=1,rule=1)' $md")->stdout;
unlike($color, qr/\x{2028}/, 'colorized: no LINE SEPARATOR is left');
like($strip->($color), qr/^\h+$V two<BR\/>\h*$/m, 'colorized: a cell is broken after <br>');

my $fold = $strip->(run("'-Mmd::config(colorize=0,table=1,rule=1,fold=1,fold_width=40)' $md")->stdout);
like($fold, qr/^ k3\h+$V - item<br>\h*\n\h+$V   - nested\h*$/m,
     'fold: the lines of a broken cell are not folded again');

my $end = run("'-Mmd::config(colorize=0,table=1,rule=1,table_trim=0)' t/table_br_end.md")->stdout;
my @end = grep { /\x{2502}/ } split /\n/, $strip->($end);
is(scalar @end, 4, 'no empty line after a <br> at the end of a cell');

my $bold = run("'-Mmd::config(table=1,rule=1)' t/table_br_end.md")->stdout;
like($bold, qr/^\h+\x{2502}\h?\e\[1mtwo\e\[m/m, 'bold over a <br> is opened again on the next line');

# br_mark colors the <br>; the nomark theme makes it empty
my $hidden = $strip->(run("-Mmd::config(table=1,rule=1) --cm 'br_mark=sub{\"\"}' -- $md")->stdout);
like($hidden, qr/^ k1\h+\x{2502} one\h*$/m, 'br_mark=sub{""}: the <br> is hidden');
like($hidden, qr/^\h+\x{2502} two\h*$/m, 'br_mark=sub{""}: <BR/> is hidden, the line break is left');
like($hidden, qr/x<br>y.? and \\<br> z/, 'br_mark=sub{""}: a <br> which breaks nothing is shown');
my $red = run("-Mmd::config(table=1,rule=1) --cm br_mark=R -- $md")->stdout;
like($red, qr/\e\[31m<br>\e\[m/, 'br_mark=R colors the <br>');

done_testing;
