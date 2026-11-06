use strict;
use warnings;
use utf8;
use Test::More;
use open qw(:std :encoding(utf-8));
use File::Temp qw(tempfile tempdir);

use lib '.';
use t::Util;

# A long block quote line is folded like a list item, and its
# continuation lines start with the quote marker again (ansifold
# --keepindent=named); a list marker inside the quote is not repeated.
# No refill is involved here.

$ENV{HOME} = tempdir(CLEANUP => 1);

my $long = join ' ', ('quote word') x 8;    # 87 columns
my($fh, $md) = tempfile(SUFFIX => '.md', UNLINK => 1);
binmode $fh, ':encoding(utf-8)';
print $fh "> $long\n\n> > $long\n\n> - $long\n\n>   $long\n\n   > $long\n\n- $long\n\n> **Bold:** $long\n";
close $fh;

sub plain { my $s = shift; $s =~ s/\e\[[0-9;]*[mK]//g; $s }

my $out = plain(run("'-Mmd::config(colorize=0,fold=1,fold_width=40)' $md")->stdout);
my @lines = split /\n/, $out;
ok((grep { s/\h+$//r =~ /^.{41,}/ } @lines) == 0, 'every quote line is folded to the fold width (a space at the fold point runs in)');
like($out, qr/^> quote.*\n> \S/m, 'a folded quote continues with the quote marker');
like($out, qr/^> > quote.*\n> > \S/m, 'a nested quote repeats both markers');
like($out, qr/^> - quote.*\n>   \S/m, 'a list marker inside a quote is replaced by spaces');
like($out, qr/^>   quote.*\n>   \S/m, 'an indented paragraph inside a quote keeps its indent after the marker');
like($out, qr/^   > quote.*\n   > \S/m, 'an indented quote keeps its indent before the marker');
like($out, qr/^- quote.*\n  \S/m, 'a list item is still indented with spaces');

$out = run("'-Mmd::config(fold=1,fold_width=40)' $md")->stdout;
like(plain($out), qr/^> quote.*\n> \S/m, 'the marker is repeated with colorize on');
like($out, qr/^   \e\[[0-9;]*m> /m, 'an indented quote marker is colored');
like($out, qr/^   \e\[[0-9;]*m> .*\n   \e\[[0-9;]*m> /m, 'an indented colored quote repeats the colored marker after the indent');
# the closing sequences of the marker belong to the prefix, the opening
# sequence of a span that follows does not: only the first line of the
# bold quote has a sequence right after the marker
my @span_after_marker = $out =~ /^\e\[[0-9;]*m(?:> )+\e\[m\e\[K\e/mg;
is(scalar @span_after_marker, 1, 'a span at the start of a quote does not bleed into the continuation lines');

# A marker with a colon in its color, as in ESC[4:3m, is a marker too
my($cfh, $cmd) = tempfile(SUFFIX => ".md", UNLINK => 1);
binmode $cfh, ":encoding(utf-8)";
print $cfh "\e[4:3m>\e[m $long\n";
close $cfh;
$out = run("'-Mmd::config(colorize=0,fold=1,fold_width=40)' $cmd")->stdout;
like($out, qr/^\e\[4:3m>\e\[m quote.*\n\e\[4:3m>\e\[m \S/m, "a marker with a colon in its color is repeated");

done_testing;
