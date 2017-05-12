use Test::More;
use Test::LongString;
use CGI;
use lib 't/lib';
use MyBase::MyApp;
use strict;

plan(tests => 3);

$ENV{'CGI_APP_RETURN_ONLY'} = 1;

# 1..3
# view_pod
{
    my $cgi = CGI->new({
        rm => 'view_pod',
    });
    my $app = MyBase::MyApp->new( QUERY => $cgi );
    my $output = $app->run();
    contains_string($output, q(<h1 id="NAME_MyBase_MyApp_Stuff">NAME MyBase::MyApp - Stuff</h1>));

    $cgi = CGI->new({
        rm     => 'view_pod',
        module => 'CGI::Application',
    });
    $app = MyBase::MyApp->new( QUERY => $cgi );
    $output = $app->run();
    contains_string($output, q(<h1 id="NAME">NAME</h1>));
    like_string($output, qr/>CGI::Application\s-\s+Framework for building reusable web-applications</);
}





