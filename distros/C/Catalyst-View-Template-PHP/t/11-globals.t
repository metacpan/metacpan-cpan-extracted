use FindBin;
use lib "$FindBin::Bin/lib";
use strict;
use warnings;
use Test::More;
use Catalyst::Test 'TestApp';
use Data::Dumper;
use HTTP::Request::Common;   # reqd for POST requests

eval "use PHP 0.13";
if ($@) {
   plan skip_all => "PHP 0.13 needed for testing";
}

BEGIN {
    no warnings 'redefine';
    *Catalyst::Test::local_request = sub {
	my ($class, $req) = @_;
	my $app = ref($class) eq "CODE" ? $class : $class->_finalized_psgi_app;
	my $ret;
	require Plack::Test;
	Plack::Test::test_psgi(
	    app => sub { $app->( %{ $_[0] } ) },
	    client => sub { $ret = shift->{request} } );
	return $ret;
    };
}

{
    my ($response, $content);

    %TestApp::Controller::Root::stash_globals = ();
    %TestApp::View::PHPTest::phptest_globals = ();
    $response = request 'http://localhost/globals.php';
    ok( $response, 'response from globals.php ok' );

    $content = eval { $response->content };
    ok( $content, 'content from globals.php available' );
    ok( $content =~ /g$_ not set/, "g$_ not set" ) for 1..5;




    %TestApp::Controller::Root::stash_globals = (
	g1 => 123,
	g2 => 456
	);

    $response = request 'http://localhost/globals.php';
    ok( $response, 'response with stash_globals ok' );
    $content = eval { $response->content };

    ok( $content, 'response has content' );
    ok( $content =~ /g1=123/, 'g1 set in stash' );
    ok( $content =~ /g2=456/, 'g2 set in stash' );
    ok( $content =~ /g5 not set/, 'g5 not set' );


    %TestApp::Controller::Root::stash_globals = (
	g3 => "foo",
	g4 => [ 1, 3, 5 ]
	);

    $response = request 'http://localhost/globals.php';
    ok( $response, 'response with stash_globals ok' );
    $content = eval { $response->content };

    ok( $content, 'response has content' );
    ok( $content =~ /g1 not set/, 'g1 set in stash' );
    ok( $content =~ /g3=foo/, 'g3 set in stash' );
    ok( $content =~ /g4=Array/, 'g4 set' );
    ok( $content =~ /g5 not set/, 'g5 not set' );



    %TestApp::Controller::Root::stash_globals = ();
    %TestApp::View::PHPTest::phptest_globals = (
	g2 => 17, g4 => "abcdefghj" );

    $response = request 'http://localhost/globals.php';
    $content = eval { $response->content };
    ok( $content =~ /g$_ not set/, "g$_ not set w/phptest_globals" ) for 1,3,5;
    ok( $content =~ /g2=17/, "g2 set w/phptest_globals" );
    ok( $content =~ /g4=abcdefghj/, "g4 set w/phptest_globals" );

    %TestApp::Controller::Root::stash_globals = (
	g1 => "abc", g2 => "def", g3 => "ghi" );
    %TestApp::View::PHPTest::phptest_globals = (
	g3 => "jkl", g4 => "mno", g5 => "pqr" );

    $response = request 'http://localhost/globals.php';
    $content = eval { $response->content };
    ok( $content =~ /g1=abc/ && $content =~ /g2=def/,
	"globals set with stash" );
    ok( $content =~ /g4=mno/ && $content =~ /g5=pqr/,
	"globals also set with phptest_globals" );
    ok( $content =~ /g3=jkl/,
	"g3 overwritten with phptest_globals" );
}

done_testing();
