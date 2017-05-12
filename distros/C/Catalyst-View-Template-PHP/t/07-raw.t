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
    my $input = q{This is some content.
There is a lot of content like it.
This content is mine.};


    my ($response, $content);
    $DB::single=1;
    $response = request( POST ('http://localhost/body',
			       Content => $input,
			       "Content-type" => 'text/plain') );

    ok( $response, 'response simple post ok' );
    $content = eval { $response->content };
    ok( $content eq $input, "received raw input back" );

    $response = request POST 'http://localhost/body.php',
    	"Content-type" => "text/plain",
	"Content" => $input;

    ok( $response, 'response simple post ok' );
    $content = eval { $response->content };
    ok( $content eq $input, 
	"received raw input back from \$HTTP_RAW_POST_DATA" );

    $response = request POST 'http://localhost/body2.php',
    	"Content-type" => "text/plain",
	"Content" => $input;
    ok( $response, 'response simple post ok' );
    $content = eval { $response->content };
    ok( $content eq $input, "received raw input back from php://input" );
}

done_testing();
