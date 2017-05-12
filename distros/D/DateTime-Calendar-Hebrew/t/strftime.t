use DateTime::Calendar::Hebrew;
print "1..15\n";

#today
my $DT = new DateTime::Calendar::Hebrew(
	year => 5763,
	month => 5,
	day => 23,
);

my %hash = (
	a => 'Thu',
	A => 'Thursday',
	B => 'Av',
	d => '23',
	D => '05/23/5763',
	e => '23',
	F => '5763-05-23',
	j => '141',
	m => '05',
	u => '4',
	U => '21',
	w => '4',
	W => '21',
	y => '63',
	Y => '5763',
);

my @formats = qw/a A B d D e F j m u U w W y Y/;
foreach $f (@formats) {
	if($hash{$f} eq $DT->strftime("%$f")) { print "ok\n"; }
	else { print "not ok\n"; }
}
exit;

