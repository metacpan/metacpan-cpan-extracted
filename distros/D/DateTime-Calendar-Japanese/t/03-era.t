#!perl
use Test::More tests => 13;

BEGIN
{
    use_ok("DateTime::Calendar::Japanese", qw(SHOUWA2 HEISEI));
}

my $dt = DateTime->new(year => 1989, month => 1, day => 7, time_zone => 'Asia/Tokyo');

my $jp1 = DateTime::Calendar::Japanese->from_object(object => $dt);
is($jp1->era_name, SHOUWA2);
is($jp1->era_year, 64);

my $dt2 = $dt + DateTime::Duration->new(days => 1);
my $jp2 = DateTime::Calendar::Japanese->from_object(object => $dt2);

is($jp2->era_name, HEISEI);
is($jp2->era_year, 1);

my $dt3 = DateTime->new(year => 1989, month => 7, time_zone => 'Asia/Tokyo');
my $jp3 = DateTime::Calendar::Japanese->from_object(object => $dt3);

is($jp3->era_name, HEISEI);
is($jp3->era_year, 2);

my $dt4 = DateTime->new(year => 2004, month => 1, time_zone => 'Asia/Tokyo');
my $jp4 = DateTime::Calendar::Japanese->from_object(object => $dt4);

is($jp4->era_name, HEISEI);
is($jp4->era_year, 16);

$jp4->set(era_year => 2);

is($jp4->era_name, HEISEI);
is($jp4->era_year, 2);

$jp4->set(cycle_year => 20);
is($jp4->era_name, HEISEI);
is($jp4->era_year, 16);

