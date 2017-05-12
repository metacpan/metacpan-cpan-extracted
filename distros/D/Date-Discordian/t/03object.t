use Test::More qw(no_plan);

BEGIN {
    use_ok ('Date::Discordian');
}

my $disco = Date::Discordian->new( disco => 'sweetmorn, chaos 1, YOLD 3166' );
is( $disco->ical, '20000101Z', 'Valid Date::ICal object' );
is( $disco->discoday, 'Sweetmorn', "Get back what we set.");
is( $disco->season, 'Chaos', "Get back what we set.");
is( $disco->yold, '3166', "Get back what we set.");

use Date::ICal;
my $ical = Date::ICal->new( ical => '20010103Z' );
bless $ical, 'Date::Discordian';
is( $ical->discordian, 'Pungenday, Chaos 3 YOLD 3167', 
    'Re-bless an ICal object into Date::Discordian');

is( $ical->discoday, 'Pungenday', 'OO interface to date components');
is( $ical->season, 'Chaos', 'OO interface to date components');
is( $ical->yold, '3167', 'OO interface to date components');
