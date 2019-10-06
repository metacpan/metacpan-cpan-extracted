use Test::More;
use DateTime::Ordinal;

sub yawn {
	my ($format, $expected) = @_;
	my %default_date = (
		year       => 3000,
		month      => 1,
		day        => 1,
		hour       => 1,
		minute     => 1,
		second     => 1,
		nanosecond => 500000000,
		time_zone => '+00:00'
	);
	%default_date = (%default_date, %{$data});
	my $dt = DateTime::Ordinal->new(%default_date);
	is ($dt->strftime($format), $expected, "expected - $expected");
}

yawn('%{day}', 1);
yawn('%{day}(f)', 'one');
yawn('%{day}(o)', '1st');
yawn('%{day}(of)', 'first');

yawn('%d', '01');
yawn('%d(o)', '1st');
yawn('%d(f)', 'one');
yawn('%d(of)', 'first');

yawn('%A the %d(o) of %B, %Y', 'Wednesday the 1st of January, 3000');
yawn('%A the %d(of) of %B, %Y', 'Wednesday the first of January, 3000');
yawn('%A the %d(f) of %B, %Y', 'Wednesday the one of January, 3000');

yawn('%m(o) month of the year', '1st month of the year');
yawn('%m(of) month of the year', 'first month of the year');
yawn('%m(f) month of the year', 'one month of the year');

yawn('the %Y(o) year', 'the 3000th year');
yawn('the %Y(f) year', 'the three thousand year');
yawn('the %Y(of) year', 'the three thousandth year');

yawn("It's the %M(o) minute of the %H(o) hour in the %j(o) day within the %m(o) month of the year", "It's the 1st minute of the 1st hour in the 1st day within the 1st month of the year");

yawn("It's the %M(of) minute of the %H(of) hour in the %j(of) day within the %m(of) month of the year", "It's the first minute of the first hour in the first day within the first month of the year");


my $dt = DateTime::Ordinal->new(
	year       => 3000,
	month      => 4,
	day        => 1,
	hour       => 2,
	minute     => 3,
	second     => 4,
);

is($dt->strftime("It's the %M(of) minute of the %H(o) hour on day %d(f) in the %m(o) month within the year %Y(f)"), "It's the third minute of the 2nd hour on day one in the 4th month within the year three thousand");


done_testing();
