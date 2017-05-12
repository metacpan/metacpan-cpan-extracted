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

sub request_with_redirect {
    my @args = @_;
    my $response = request @args;
    if ($response->header('location')) {
	use URI;
	my $uri = URI->new( $response->header('location') );
	$response = request $uri->path;
    }
    return $response;
}


{
    @TestApp::View::PHPTest::headers = ();
    $TestApp::View::PHPTest::capture_all_headers = 1;
    my $response = request 'http://localhost/redirect.php?location=1';
    my $content = eval { $response->content };

    ok( $response, 'response ok for redirect' );
    ok( $content,  'got content for request with redirect' );
    ok( $response->code == 302, 'got default status' );
}

{
    my $response = request_with_redirect 'http://localhost/redirect.php?location=1';
    my $content  = eval { $response->content };
    ok( $response, 'response ok with redirect' );
    ok( $content =~ /reached redirect_destination.php/,
	'retrieved content from redirected location' );

    $response = request_with_redirect 'http://localhost/redirect.php?location=2';
    $content = eval { $response->content };
    ok( $response, 'response ok with redirect' );
    ok( $content =~ /reached redirect_destination2.php/,
	'retrieved content from redirected location' );
    ok( $response->code == 200, 'status after redirect is OK' );

}

{
    @TestApp::View::PHPTest::headers = ();
    $TestApp::View::PHPTest::capture_all_headers = 1;
    my $response = request 'http://localhost/redirect.php?location=2&status=301';
    my $content = eval { $response->content };

    ok( $response, 'response ok for redirect' );
    ok( $content,  'got content for request with redirect and status' );
    ok( grep(/Status: 301/,@TestApp::View::PHPTest::headers),
	"got correct status");
#   ok( $response->code == 301, 'got correct status' );
}

{
    @TestApp::View::PHPTest::headers = ();
    $TestApp::View::PHPTest::capture_all_headers = 1;
    my $response = request 'http://localhost/redirectx.php?location=2&status=303';
    my $content = eval { $response->content };

    ok( $response, 'response ok for redirect' );
    ok( $content,  'got content for request with redirect and status' );
    ok( grep(/Status: 301/,@TestApp::View::PHPTest::headers),
	"got correct status");
}

done_testing();
