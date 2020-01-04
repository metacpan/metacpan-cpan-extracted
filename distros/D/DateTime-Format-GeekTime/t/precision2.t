#!perl
use Test::More;
use DateTime;
use DateTime::Format::GeekTime;

if ($ENV{SLOW_TESTS}) {
    plan tests=>86400;
}
else {
    plan skip_all => 'Slow test, set $ENV{SLOW_TESTS} to run it';
}

my $dt=DateTime->new(day=>1,month=>1,year=>2010,
                     hour=>0,minute=>0,second=>0,
                     time_zone=>'UTC');

my $formatter= DateTime::Format::GeekTime->new(2010);

for my $i (0..86399) {
    my $gkt=$formatter->format_datetime($dt);
    my $round_trip=$formatter->parse_datetime($gkt);
    my $diff=$round_trip->subtract_datetime_absolute($dt)->in_units('seconds');
    cmp_ok($diff,'<=',1,"$round_trip - $dt");
    $dt->add(seconds=>1);
}
