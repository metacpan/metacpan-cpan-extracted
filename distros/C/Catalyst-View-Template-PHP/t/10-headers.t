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
    my $response = request POST 'http://localhost/headers.php', [
	abc => 123,
	def => 456
    ];

    ok( $response, 'response simple post ok' );
    my $content = eval { $response->content };

    ok( $TestApp::View::PHPTest::last_header, 'header callback was called' );
    ok( $TestApp::View::PHPTest::first_header, 'header callback was called' );
    ok( scalar @TestApp::View::PHPTest::headers, 'header callback was called' );

    ok( $TestApp::View::PHPTest::first_header eq 'X-header-abc: 123',
	'last header correct' );
    ok( $TestApp::View::PHPTest::last_header eq 'X-header-def: 456',
	'last header correct' );
    ok( $TestApp::View::PHPTest::headers[0] eq $TestApp::View::PHPTest::last_header &&
	$TestApp::View::PHPTest::headers[1] eq $TestApp::View::PHPTest::first_header,
	'header list set correctly' );

    # use headers and the header callback as a channel for PHP/Perl
    # communication.
    $response = request 'http://localhost/header_compute.php';
    $content = eval { $response->content };
    ok( $response, 'response ok for header_compute.php' );
    ok( $content,  'got content for header_compute.php' );
    ok( $content =~ /begin result/, 'found result begin marker' );
    ok( $content =~ /end result/, 'found result end marker' );
    ok( $content !~ /Input/, 'post had no requests, so there are no results' );

    $response = request POST 'http://localhost/header_compute.php', [
	expr1 => 'exp(5.5 * log(14.14))',
	expr6 => '$INC{"PHP.pm"}'
    ];
    $content = eval { $response->content };
    ok( $response, 'response ok for header_compute.php' );
    ok( $content,  'got content for header_compute.php' );
    ok( $content =~ /begin result/, 'found result begin marker' );
    ok( $content =~ /end result/, 'found result end marker' );
    ok( $content =~ /Input \# 1/, 'echoed expression #1' );
    ok( $content =~ /Input \# 6/, 'echoed expression #6' );
    ok( $content !~ /Input \# 2/, 'no expression #2 to echo' );
    ok( $content !~ /Input \# 5/, 'no expression #5 to echo' );
    ok( $content !~ /Input \# 8/, 'no expression #8 to echo' );
    my ($result1) = $content =~ /Output\# 1:\s+(.*)/;
    my ($result6) = $content =~ /Output\# 6:\s+(.*)/;

    ok( $result1, 'got result for expression #1' );
    ok( $result6, 'got result for expression #6' );
    ok( abs($result1 - (14.14**5.5)) < 1.0E-2,
	'result #1 was correct expression for 14.14**5.5' )
	or diag 14.14**5.5;
    ok( $result6 =~ m{/PHP\.pm} , 'result #6 looks correct' );
}

if ($PHP::VERSION >= 0.15) {
    # requires PHP 0.15
    my $response = request 'http://localhost/php/headers2.php';
    ok( $response, 'simple response from header2.php' );
#   diag Dumper($response);

    ok( ref($response->header("foo")) ne 'ARRAY' &&
	$response->header("foo") eq 'baz',
	'default header callback respects $replace=true' );

    my $header_123 = $response->header("123");
    ok( (ref($header_123) eq 'ARRAY' &&
	 $header_123->[0] eq '456' &&
	 $header_123->[1] eq '789') ||
	(ref($header_123) ne 'ARRAY' &&
	 $header_123 eq '456, 789') ,
	'default header callback respects $replace=false' )
	or diag Dumper($header_123);

    ok( ref($response->header('abc')) ne 'ARRAY' &&
	$response->header("abc") eq 'jkl',
	'default header callback default $replace is true' );
} else {
    diag "PHP 0.15 required to test replace argument in header callback";
}

done_testing();
