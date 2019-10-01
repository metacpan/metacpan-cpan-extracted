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
yawn('%{day}(o)', '1st');

yawn('%d', '01');
yawn('%d(o)', '1st');

yawn('%A the %d(1) of %B, %Y', 'Wednesday the 1st of January, 3000');
yawn('%m(o) month of the year', '1st month of the year');
yawn('the %Y(o) year', 'the 3000th year');
yawn("It's the %M(o) minute of the %H(o) hour in the %j(o) day within the %m(o) month of the year", "It's the 1st minute of the 1st hour in the 1st day within the 1st month of the year");

#yawn("It's the %M(f) minute of the %H(f) hour in the %j(f) day within the %m(f) month of the year", "It's the first minute of the first hour in the first day within the first month of the year");

done_testing();
