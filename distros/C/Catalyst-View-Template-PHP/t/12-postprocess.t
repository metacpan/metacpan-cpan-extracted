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

    $TestApp::View::PHPTest::postprocessor = sub {
	my $output = shift;
	$output =~ s/5/7/g;
	$output;
    };

    $response = request 'http://localhost/globals.php';
    ok( $response, 'response with stash_globals ok' );
    $content = eval { $response->content };

    ok( $content, 'response has content' );
    ok( $content =~ /g1=123/, 'g1 set in stash' );
    ok( $content =~ /g2=476/, 'g2 set in stash, output postprocessed' );
    ok( $content =~ /g7 not set/, 'g5 not set, output postprocesed' );


    %TestApp::Controller::Root::stash_globals = (
	g3 => "foo",
	g4 => [ 1, 3, 5 ]
	);
    $TestApp::View::PHPTest::postprocessor = sub {
	return "this content has been deleted";
    };

    $response = request 'http://localhost/globals.php';
    ok( $response, 'response with stash_globals ok' );
    $content = eval { $response->content };

    ok( $content, 'response has content' );
    ok( $content eq 'this content has been deleted',
	'output postprocessed' );


    %TestApp::Controller::Root::stash_globals = ();
    %TestApp::View::PHPTest::phptest_globals = (
	g2 => 17, g4 => "abcdefghj" );

    $TestApp::View::PHPTest::postprocessor = sub {
	my $output = shift;
	my $g4 = reverse PHP::eval_return('$g4');
	$output .= "<pre>\nreverse G4 is $g4\n</pre>\n";
	return $output;
    };

    $response = request 'http://localhost/globals.php';
    ok( $response, 'response with stash_globals ok' );

    $content = eval { $response->content };
    ok( $content, 'response has content' );
    ok( $content =~ /reverse G4 is jhgfedcba/,
	'output postprocessor has access to PHP interpreter' );
}

done_testing();
