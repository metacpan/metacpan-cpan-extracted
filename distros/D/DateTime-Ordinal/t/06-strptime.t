use Test::More;

use DateTime::Ordinal;

sub yawn {
	my ($pattern, $date, $meth, $expected) = @_;
	my $dt = DateTime::Ordinal->strptime($pattern, $date);
	is($dt->$meth('f'), $expected, "expected - $expected");
}

yawn('%H:%M', '21:20', 'hour', 'twenty-one');
yawn('%H:%M', '21:20', 'minute', 'twenty');

done_testing();

