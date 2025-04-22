use Test::More;
use DateTime::Ordinal;
use utf8;
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
	my $f = $dt->strftime($format);
	$f =~ s/\x{202f}/ /;
	is ($f, $expected, "expected - $expected");
}

yawn('%a', 'Wed');
yawn('%A', 'Wednesday');
yawn('%b', 'Jan');
yawn('%B', 'January');
yawn('%c', 'Jan 1, 3000, 1:01:01 AM');
yawn('%C', 30);
yawn('%C(1)', '30th');
yawn('%d', '01');
yawn('%D', '01/01/00');
yawn('%e', ' 1');
yawn('%e(o)', '1st');
yawn('%F', '3000-01-01');
yawn('%g', '1');
yawn('%g(1)', '1st');
yawn('%G', '1');
yawn('%G(o)', '1st');
yawn('%H', '01');
yawn('%H(o)', '1st');
yawn('%I', '01');
yawn('%I(o)', '1st');
yawn('%j', '001');
yawn('%j(o)', '1st');
yawn('%k', ' 1');
yawn('%k(o)', '1st');
yawn('%l', ' 1');
yawn('%l(o)', '1st');
yawn('%m', '01');
yawn('%m(o)', '1st');
yawn('%M', '01');
yawn('%M(o)', '1st');
yawn('%n', "\n");
yawn('%N(10)', "5000000000");
yawn('%p', "AM");
yawn('%P', "am");
yawn('%r', "01:01:01 AM");
yawn('%R', "01:01");
yawn('%s', "32503683661");
yawn('%t', "\t");
yawn('%T', "01:01:01");
yawn('%u', "3");
yawn('%U', "00");
yawn('%V', "00");
yawn('%w', "3");
yawn('%w(o)', "3rd");
yawn('%W', "00");
yawn('%x', "Jan 1, 3000");
yawn('%X', "1:01:01 AM");
yawn('%y', "00");
yawn('%y(o)', "00th");
yawn('%z', "+0000");
yawn('%Z', "UTC");
yawn('%%', "%");
yawn('%{day}(oe)', 'st');




done_testing();
