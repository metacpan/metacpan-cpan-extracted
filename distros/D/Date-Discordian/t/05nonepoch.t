use Test::More qw(no_plan);

BEGIN {
    use_ok('Date::Discordian');
}

my $d;

$d = Date::Discordian->new( ical => '17760704Z' );
is($d->discordian, 'Setting Orange, Confusion 39 YOLD 2942',
"Declaration of Independance" );

$d = Date::Discordian->new( ical => '10660105Z' );
is($d->discordian, 'Setting Orange (Mungoday), Chaos 5 YOLD 2232',
"Battle of Hastings" );

$d = Date::Discordian->new( ical => '19421207Z' );
is($d->discordian, 'Sweetmorn, Aftermath 49 YOLD 3108', "Pearl Harbor" );

$d = Date::Discordian->new( ical => '18831204Z' );
is($d->discordian, 'Pungenday, Aftermath 46 YOLD 3049', "Random" );
