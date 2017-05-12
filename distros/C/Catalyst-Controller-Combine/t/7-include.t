use Test::More;
use Test::Exception;
use Catalyst ();
use FindBin;
use DateTime;
use DateTime::Duration;


# a simple package
{
    package MyApp::Controller::Css;
    use Moose;
    extends 'Catalyst::Controller::Combine';

    __PACKAGE__->config(
        include => [
            qr{\@import \s+ (?:url\s*\()? ["']? ([^"')]+) ["']? [)]? .*? ;}xms
        ]
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
lives_ok { $controller = $c->setup_component('MyApp::Controller::Css') } 'setup component worked';

lives_ok { $controller->do_combine($c, 'include_parent.css') } 'including works';

like $c->response->body,
     qr{parent\s+begin    .*
        child\s+1\s+begin .*
        child\s+2         .*
        child\s+1\s+end   .*
        child\s+3         .*
        parent\s+end}xms,
     'included content looks good';


done_testing;
