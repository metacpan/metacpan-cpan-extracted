use Test::More;
use Test::Exception;
use Catalyst ();
use FindBin;
use DateTime;
use DateTime::Duration;

plan skip_all => 'this test is skipped under windows' if ($^O =~ m{Win}xms);

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

# setup our Catalyst :-)
my $c = Catalyst->new();
$c->setup_log();
$c->setup_home("$FindBin::Bin");

my $controller;
lives_ok { $controller = $c->setup_component('MyApp::Controller::Js') } 'setup component worked';


#
# check if expires header is sent, if feature isn't turned on
#
$c->response->body('');
lives_ok { $controller->do_combine($c, 'js1') } 'file inside root_dir lives';

$c->response->body('');
dies_ok { $controller->do_combine($c, 'js1', '../../../6-security.t') } 'file outside root_dir dies';

$c->response->body('');
lives_ok { $controller->do_combine($c, 'js1', '../../../xx_notexisting.js') } 'not existing file outside root_dir lives';

done_testing;
