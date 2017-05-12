use Test::More qw(no_plan);

BEGIN {
    use_ok ('Date::Discordian');
}

# These tests are to check for several one-off bugs discovered by Jean
# <J-FORGET@wanadoo.fr>, who sent me a very interesting note that
# mentioned these bugs, as well as making a variety of other comments
# about the module and documentation. Thanks, Jean.

my $disco;

$disco = Date::Discordian->new( ical => '20010313Z' );
is( $disco->discordian, 'Boomtime, Chaos 72 YOLD 3167', "March 13 2001");

$disco = Date::Discordian->new( ical => '20010314Z' );
is( $disco->discordian, 'Pungenday, Chaos 73 YOLD 3167', "March 14 2001");

$disco = Date::Discordian->new( ical => '20010315Z' );
is( $disco->discordian, 'Prickle Prickle, Discord 1 YOLD 3167', "March 15 2001");

$disco = Date::Discordian->new( ical => '20011018Z' );
is( $disco->discordian, 'Sweetmorn, Bureaucracy 72 YOLD 3167', "Oct 18 2001");

$disco = Date::Discordian->new( ical => '20011019Z' );
is( $disco->discordian, 'Boomtime, Bureaucracy 73 YOLD 3167', "Oct 19 2001");

$disco = Date::Discordian->new( ical => '20011020Z' );
is( $disco->discordian, 'Pungenday, Aftermath 1 YOLD 3167', "Oct 20 2001");

# Fix so that an epoch time of 0, as opposed to undef, returns Jan 1,
# 1970, but, hopefully, if no arg is supplied at all, we get today, for
# an appropriate value of 'today'.
$disco = Date::Discordian->new( ical => '19700101Z' );
is( $disco->discordian, 'Sweetmorn, Chaos 1 YOLD 3136', "Jan 1, 1970");

$disco = Date::Discordian->new( epoch => time );
is( $disco->discordian, discordian(), "discordian with no arg should return current time");

# It appears that all of our tests are either in 2000 or 2001, producing
# a real uncertainty as to whether this works any other time.
$disco = Date::Discordian->new( ical => '19830101Z' );
is($disco->discordian, 'Sweetmorn, Chaos 1 YOLD 3149' );

$disco = Date::Discordian->new( ical => '19831025Z' );
is($disco->discordian, 'Pungenday, Aftermath 6 YOLD 3149' );

$disco = Date::Discordian->new( ical => '19840101Z' );
is($disco->discordian, 'Sweetmorn, Chaos 1 YOLD 3150' );

$disco = Date::Discordian->new( ical => '19841025Z' );
is($disco->discordian, 'Pungenday, Aftermath 6 YOLD 3150' );

