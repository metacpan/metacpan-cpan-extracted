use Test::More;

BEGIN {
    eval {
        require Lingua::ITA::Numbers;
        Lingua::ITA::Numbers->new();
        1;
    } or do {
        plan skip_all => "Moose is not available";
    };
}
use Data::Dumper;
use DateTime::Ordinal (
	sub_format => {
		f => sub {
			my $number = Lingua::ITA::Numbers->new(shift);
			return $number->get_string;
		}
	}
);

sub yawn {
	my ($meth, $data, $expected) = @_;
	my %default_date = (
		year       => 2000,
		month      => 1,
		day        => 1,
		hour       => 1,
		minute     => 2,
		second     => 3,
		nanosecond => 500000000,
		time_zone => '+00:00',
		locale => 'it'
	);
	%default_date = (%default_date, %{$data});
	my $dt = DateTime::Ordinal->new(%default_date);
	is ($dt->$meth('f'), $expected, "cardinal: $expected");
}

yawn('day', {}, 'uno');
yawn('day', {day => 2}, 'due');
yawn('day', {day => 7}, 'sette');
yawn('day', {day => 20}, 'venti');

done_testing();

