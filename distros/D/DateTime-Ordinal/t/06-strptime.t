use Test::More;

BEGIN {
    eval {
        require DateTime::Format::Strptime;
        DateTime::Format::Strptime->new();
        1;
    } or do {
        plan skip_all => "Moose is not available";
    };
}

use DateTime::Ordinal;

sub yawn {
	my ($pattern, $date, $meth, $expected) = @_;
	my $dt = DateTime::Ordinal->strptime($pattern, $date);
	is($dt->$meth('f'), $expected, "expected - $expected");
}

yawn('%H:%M', '21:20', 'hour', 'twenty-one');
yawn('%H:%M', '21:20', 'minute', 'twenty');

done_testing();

