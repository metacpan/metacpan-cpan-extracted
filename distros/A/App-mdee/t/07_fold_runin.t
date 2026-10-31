use strict;
use warnings;
use utf8;
use Test::More;
use open qw(:std :encoding(utf-8));
use Text::ANSI::Fold::Util qw(ansi_width);
use File::Temp qw(tempfile);

use lib '.';
use t::Util;

# fold_runin and fold_runout are given to ansifold, so that the lines
# it folds run in by that width and not more.  "。" may not start a
# line; with run-in it goes past the width, without it the line is
# broken before the word.

$ENV{HOME} = File::Temp::tempdir(CLEANUP => 1);

my($fh, $md) = tempfile(SUFFIX => '.md', UNLINK => 1);
# "- " + 14 double-width chars = 30 columns, then "。" (2 columns)
print $fh "- " . ("あ" x 14) . "。" . ("い" x 10) . "。\n";
close $fh;

sub max_width {
    my $out = shift;
    $out =~ s/\e\[[0-9;]*[mK]//g;
    my $max = 0;
    for (split /\n/, $out) {
	my $w = ansi_width($_);
	$max = $w if $w > $max;
    }
    $max;
}

for my $case ([ 0, 30 ], [ 2, 32 ], [ 4, 32 ]) {
    my($run, $want) = @$case;
    my $out = run("'-Mmd::config(colorize=0,foldlist=1,foldwidth=30,fold_runin=$run,fold_runout=$run)' $md")->stdout;
    is(max_width($out), $want, "fold_runin=$run: widest line is $want columns");
}

done_testing;
