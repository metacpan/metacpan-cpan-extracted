use Test::Most 0.25;

use Date::Easy;


my $FMT = '%Y/%m/%d %H:%M:%S';


my @units = qw< seconds minutes hours days weeks months years >;
foreach (@units)
{
	my $unit_func = \&{ $_ };
	my $unit = $unit_func->();

	(my $singular = $_) =~ s/s$//;
	is $unit, "1 $singular", "singular version works: $_";

	my $multiple;
	lives_ok { $multiple = $unit * 4 } "multiplication works: $_";
	is $multiple, "4 $_", "plural version works: $_";

	throws_ok { $unit * 1.5   } qr/can only do integer math/, "multiplication rejects floating point: $_";

	my $dt = datetime("Jan-02-2003 04:05:06");
	my $method = "add_$_";
	is $dt + $multiple, $dt->$method(4), "datetime addition works forwards: $_";
	is $multiple + $dt, $dt->$method(4), "datetime addition works backwards: $_";

	$method = "subtract_$_";
	is $dt - $multiple, $dt->$method(4), "datetime subtraction works forwards: $_";
	throws_ok { $multiple - $dt } qr/can't subtract from a unit/, "datetime subtraction fails backwards: $_";

	# for dates, units prior to "days" should fail
	my $d = date("Jan-02-2003");
	if (/days/../years/)
	{
		my $method = "add_$_";
		is $d + $multiple, $d->$method(4), "date addition works forwards: $_";
		is $multiple + $d, $d->$method(4), "date addition works backwards: $_";

		$method = "subtract_$_";
		is $d - $multiple, $d->$method(4), "date subtraction works forwards: $_";
		throws_ok { $multiple - $d } qr/can't subtract from a unit/, "date subtraction fails backwards: $_";
	}
	else
	{
		throws_ok { $d + $multiple } qr/cannot call/, "date addition of $_ fails";
		throws_ok { $d - $multiple } qr/cannot call/, "date subtraction of $_ fails";
	}
}


# test prototypes and also try a few more complex formulae
my $dt = datetime("Jan-02-2003 04:05:06");
my $dt2;
lives_ok { $dt2 = $dt + 2*days + 5*hours - 8*years + 10*seconds - 3*minutes } "complex example parses correctly";
is $dt2->strftime($FMT), "1995/01/04 09:02:16", "complex example (including prototypes) works";


# test a few more errors
throws_ok { seconds + minutes } qr/can't locate object method/i, "cannot add two units together";
throws_ok { seconds - minutes } qr/can't subtract from a unit/i, "cannot subtract two units from each other";


done_testing;
