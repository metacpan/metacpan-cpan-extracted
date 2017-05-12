#!/usr/bin/perl -w
use strict;
use Test::More (tests => 1);

BEGIN {use Chart::Gnuplot;}

my $temp = "temp.ps";

# Test default setting of the time stamp
{
    my $c = Chart::Gnuplot->new(
        output => $temp,
        x2tics => 'on',
		y2tics => 'on',
    );

	my $d = Chart::Gnuplot::DataSet->new(
		func => 'sin(x)',
		axes => 'x2y2',
	);

    $c->_setChart([$d]);
	my $s = $d->_thaw($c);
    ok( &diff($c->{_script}, "plotAxes_1.gp") == 0 &&
		$s eq 'sin(x) title "" axes x2y2' );
}

###################################################################

# Compare two files
# - return 0 if two files are the same, except the ordering of the lines
# - return 1 otherwise
sub diff
{
    my ($f1, $f2) = @_;
    $f2 = "t/".$f2 if (!-e $f2);

    open(F1, $f1) || return(1);
    open(F2, $f2) || return(1);
    my @c1 = <F1>;
    my @c2 = <F2>;
    close(F1);
    close(F2);
    return(0) if (join("", sort @c1) eq join("", sort @c2));
    return(1);
}
