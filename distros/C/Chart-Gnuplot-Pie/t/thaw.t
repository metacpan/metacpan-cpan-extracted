use warnings;
use strict;
use Test::More (tests => 1);

BEGIN {use Chart::Gnuplot::Pie;}

# Test plotting 2d pie chart
{
	my $c = Chart::Gnuplot::Pie->new();
    my $d = Chart::Gnuplot::Pie::DataSet->new(
		data => [
			['A', 1],
			['B', 2],
			['C', 3],
			['D', 4],
		],
		colors => ["#99ccff", "#cc99ff", "#ccff99", "#ffcc99"],
    );

    my $s = $d->_thaw2d($c);

	my @cmd = (
		'set label "A" at cos((0+0.1)*pi)*1.1, sin((0+0.1)*pi)*1.1, 0.2 front noenhanced',	
		'set label "B" at cos((0.1+0.3)*pi)*1.1, sin((0.1+0.3)*pi)*1.1, 0.2 front noenhanced',
		'set label "C" at cos((0.3+0.6)*pi)*1.1, sin((0.3+0.6)*pi)*1.1, 0.2 right front noenhanced',
		'set label "D" at cos((0.6+1)*pi)*1.1, sin((0.6+1)*pi)*1.1, -0.1 front noenhanced',
		'set palette model RGB functions 0.6, 0.8, 1',
		'splot cos(2*pi*((0.1-0)*u+0))*v, sin(2*pi*((0.1-0)*u+0))*v, 0.1 with pm3d',
		'set palette model RGB functions 0.8, 0.6, 1',
		'splot cos(2*pi*((0.3-0.1)*u+0.1))*v, sin(2*pi*((0.3-0.1)*u+0.1))*v, 0.1 with pm3d',
		'set palette model RGB functions 0.8, 1, 0.6',
		'splot cos(2*pi*((0.6-0.3)*u+0.3))*v, sin(2*pi*((0.6-0.3)*u+0.3))*v, 0.1 with pm3d',
		'set palette model RGB functions 1, 0.8, 0.6',
		'splot cos(2*pi*((1-0.6)*u+0.6))*v, sin(2*pi*((1-0.6)*u+0.6))*v, 0.1 with pm3d',
		'',
	);

    ok($s eq join("\n", @cmd));
}
