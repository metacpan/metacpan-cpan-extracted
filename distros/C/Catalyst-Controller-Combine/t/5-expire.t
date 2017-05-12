use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catalyst ();
use FindBin;
use DateTime;

# a simple package
{
    package MyApp::Controller::Js;
    use Moose;
    extends 'Catalyst::Controller::Combine';

    __PACKAGE__->config(
    #    expire    => 1,
    #    expire_in => 60 * 60, # 1 hour
    );
}


#
# test start...
#

# setup our Catalyst :-)
my $c = Catalyst->new();
$c->setup_log();
$c->setup_home("$FindBin::Bin");

my $controller;
lives_ok { $controller = $c->setup_component('MyApp::Controller::Js') } 'setup component worked';


#
# check if expires header is sent, if feature isn't turned on
#
$controller->do_combine($c, 'js1');
ok(!$c->response->header('expires'), "expires header not sent, if feature not active");


# okay, let's check the real stuff, turn this feature one
MyApp::Controller::Js->config->{expire} = 1;
$controller = $c->setup_component('MyApp::Controller::Js');


#
# combine and check if expire header is set and correct (no expire_in is explicitly set)
#
{
	no warnings 'redefine';
    my $now = DateTime->now( time_zone => 'floating' );
	my $test_date_time = DateTime->new(
		year => 2012, month => 1, day => 4,
		hour => 12, minute => 13, second => 14, 
	);
    
	local *DateTime::now = sub { return $test_date_time->clone };
    
    $controller->do_combine($c, 'js1');
    my $expected_date =
		$test_date_time->clone
                       ->add(seconds => $controller->{expire_in} || 0)
                       ->strftime('%a, %d %b %Y %H:%M:%S GMT');
    is $c->response->header('expires'), $expected_date, 'expired header date is OK 1';

    # set expiry to 1 hour
    MyApp::Controller::Js->config->{expire_in} = 60 * 60;
    $controller = $c->setup_component('MyApp::Controller::Js');

    $controller->do_combine($c, 'js1');
    $expected_date =
		$test_date_time->clone
		               ->add(seconds => 3600)
		               ->strftime('%a, %d %b %Y %H:%M:%S GMT');
    is $c->response->header('expires'), $expected_date, 'expired header date is OK 2';
}


done_testing;
