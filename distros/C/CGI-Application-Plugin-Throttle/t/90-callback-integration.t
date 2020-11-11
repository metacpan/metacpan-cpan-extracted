use Test::More;

use strict;
use warnings;

use Test::Time time => 7; # so, only 3 seconds left in this time slot

use Test::WWW::Mechanize::CGIApp;

my $mech = Test::WWW::Mechanize::CGIApp->new;
$mech->app('MyTest::CGI::Application');
foreach (1..3)
{
    $mech->get( 'https://test.tst/test.cgi' );
    my $content = $mech->content;
    is( $content, 'SIMPLE TEST', "Time Slot 1: Simple Test");
    sleep 1;
}

foreach (1..5)
{
    $mech->get( 'https://test.tst/test.cgi' );
    my $content = $mech->content;
    is( $content, 'SIMPLE TEST', "Time Slot 2: Simple Test");
    sleep 1;
}

foreach (1..5)
{
    $mech->get( 'https://test.tst/test.cgi' );
    my $content = $mech->content;
    is( $content, 'THROTTLED MORE', "Time Slot 2: Throttled");
    sleep 1;
}

foreach (1..2)
{
    $mech->get( 'https://test.tst/test.cgi' );
    my $content = $mech->content;
    is( $content, 'SIMPLE TEST', "Time Slot 3: Simple Test");
    sleep 1;
}


done_testing();




package MyTest::CGI::Application;

use strict;
use warnings;

use base 'CGI::Application';
use CGI::Application::Plugin::Throttle;

use Test::Mock::Redis;


sub setup
{
    my $self = shift;
    $self->throttle->configure(
        redis => Test::Mock::Redis->new(server => 'redis_tester' ),
        # leava defaults
    );

    $self->run_modes(
        start       => 'simple_test',
        slow_down   => 'throttled',
        slow_more   => 'throttled_more',
    );

}

sub throttle_keys
{
    foo => 1
}

sub throttle_spec
{
    { foo => 1 } =>
    {
        limit    => 5,
        period   => 10,
        exceeded => 'slow_more',
    },
}

sub simple_test
{
    'SIMPLE TEST'
}

sub throttled
{
    'THROTTLED'
}

sub throttled_more
{
    'THROTTLED MORE'
}