use Test::More;

use DateTime::Ordinal;

BEGIN {
    eval {
        require DateTime::Format::Strptime;
        DateTime::Format::Strptime->new(
		pattern   => '%T',
    		locale    => 'en_AU',
    		time_zone => 'Australia/Melbourne',
	);
        1;
    } or do {
        plan skip_all => "DateTime::Format::Strptime is not available";
    };
}

sub yawn {
	my ($pattern, $date, $meth, $expected) = @_;
	my $dt = DateTime::Ordinal->strptime($pattern, $date);
	is($dt->$meth('f'), $expected, "expected - $expected");
}

yawn('%H:%M', '21:20', 'hour', 'twenty-one');
yawn('%H:%M', '21:20', 'minute', 'twenty');

done_testing();

