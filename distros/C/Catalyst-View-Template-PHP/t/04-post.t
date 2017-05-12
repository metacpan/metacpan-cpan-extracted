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

my $entrypoint = "http://localhost/foo";

{
    my $response = request('http://localhost/vars.php');
    ok( $response, 'response no params ok' );
    my $content = eval { $response->content };
    ok( $content =~ /_GET = array *\(\s*\)/, '$_GET is empty' );
    ok( $content =~ /_POST = array *\(\s*\)/, '$_POST is empty' );
    ok( $content =~ /_REQUEST = array *\(\s*\)/, '$_REQUEST is empty' );
    ok( $content =~ /_SERVER = array/ &&
	$content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
    ok( $content =~ /_ENV = array/ &&
	$content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
    ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );

$DB::single=1;
    $response = request POST 'http://localhost/vars.php', [
	abc => 123,
	def => 456
    ];
$DB::single = 1;
    ok( $response, 'response simple post ok' );
    $content = eval { $response->content };
    ok( $content =~ /_GET = array *\(\s*\)/, '$_GET is empty' );
    ok( $content !~ /_POST = array *\(\s*\)/, '$_POST not empty' );
    ok( $content =~ /_POST.*abc.*=.*123.*_REQUEST/s, '$_POST["abc"] ok');
    ok( $content =~ /_POST.*def.*=.*456.*_REQUEST/s, '$_POST["def"] ok');
    ok( $content !~ /_REQUEST = array *\(\s*\)/, '$_REQUEST not empty' );
    ok( $content =~ /_REQUEST.*abc.*=.*123.*_SERVER/s &&
	$content =~ /_REQUEST.*def.*=.*456.*_SERVER/s, '$_REQUEST mimics $_POST' );
    ok( $content =~ /_SERVER = array/ &&
	$content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
    ok( $content =~ /_ENV = array/ &&
	$content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
    ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );



    # When PHP receives a duplicate param name, it ignores all values
    # except the last value.
    $response = request POST 'http://localhost/vars.php', [
	abc => 123,
	def => 456,
	abc => 789
    ];

    ok( $response, 'response post with duplicate ok' );
    $content = eval { $response->content };
    ok( $content =~ /_GET = array *\(\s*\)/, '$_GET is empty' );
    ok( $content !~ /_POST = array *\(\s*\)/, '$_POST not empty' ); 
    ok( $content !~ /_POST.*abc.*=.*123.*_REQUEST/s, 'lost first val for $_POST["abc"]');
    ok( $content =~ /_POST.*abc.*=.*789.*_REQUEST/s, 'got last val for $_POST["abc"]');
    ok( $content =~ /_POST.*def.*=.*456.*_REQUEST/s, '$_POST["def"] ok');
    ok( $content !~ /_REQUEST = array *\(\s*\)/, '$_REQUEST not empty' );
    ok( $content !~ /_REQUEST.*abc.*=.*123.*_SERVER/s &&
	$content =~ /_REQUEST.*abc.*=.*789.*_SERVER/s &&
	$content =~ /_REQUEST.*def.*=.*456.*_SERVER/s, '$_REQUEST mimics $_POST' );
    ok( $content =~ /_SERVER = array/ &&
	$content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
    ok( $content =~ /_ENV = array/ &&
	$content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
    ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );


    # When PHP receives a param name like  foo[bar] , it creates an 
    # associative array param named foo with key bar.
    $response = request POST 'http://localhost/vars.php', [
	'foo[x]' => 1,
	'foo[y]' => 2,
	'foo[z]' => 3
    ];

    ok( $response, 'response post array ok' );
    $content = eval { $response->content };
    ok( $content =~ /_GET = array *\(\s*\)/, '$_GET is empty' );

    ok( $content !~ /_POST = array *\(\s*\)/, '$_POST not empty' ); 
    my $z = $content =~ /_POST.*foo(.*)\$_REQUEST/s;
    my $foo = $1;
    ok( $z, '$_POST["foo"] was set' );
    ok( $foo =~ /array/, '$_POST["foo"] was set to a PHP array' );
    ok( $foo =~ /x.*1/, '$_POST["foo"]["x"] was set' );
    ok( $foo =~ /y.*2/, '$_POST["foo"]["y"] was set' );
    ok( $foo =~ /z.*3/, '$_POST["foo"]["z"] was set' );

    ok( $content !~ /_REQUEST = array *\(\s*\)/, '$_REQUEST not empty' );
    ok( $content !~ /_REQUEST.*abc.*=.*123.*_SERVER/s &&
	$content =~ /_REQUEST.*foo.*array.*z.*3.*_SERVER/s,
	'$_REQUEST mimics $_GET' );
    ok( $content =~ /_SERVER = array/ &&
	$content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
    ok( $content =~ /_ENV = array/ &&
	$content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
    ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );


    # 2-level hash
    $response = request POST 'http://localhost/vars.php', [
	'foo[4][x]' => 1,
	'foo[4][y]' => 2,
	'foo[5][z]' => 3
    ];

    ok( $response, 'response post array ok' );
    $content = eval { $response->content };
    ok( $content =~ /_GET = array *\(\s*\)/, '$_GET is empty' );

    ok( $content !~ /_POST = array *\(\s*\)/, '$_POST not empty' ); 
    $z = $content =~ /_POST.*foo(.*)\$_REQUEST/s;
    $foo = $1;
    ok( $z, '$_POST["foo"] was set' );
    ok( $foo =~ /array/, '$_POST["foo"] was set to a PHP array' );
    ok( $foo =~ /x.*1/, '$_POST["foo"]["x"] was set' );
    ok( $foo =~ /y.*2/, '$_POST["foo"]["y"] was set' );
    ok( $foo =~ /z.*3/, '$_POST["foo"]["z"] was set' );

    ok( $foo =~ /array.*array.*array/s,
	'$_POST["foo"] looks like 2-level hash' );
    ok( $foo =~ /array.*4.*array.*y.*2/s,
	'$_POST["foo"] looks like 2-level hash' );
    ok( $foo =~ /array.*5.*array.*z.*3/s,
	'$_POST["foo"] looks like 2-level hash' );

    ok( $content !~ /_REQUEST = array *\(\s*\)/, '$_REQUEST not empty' );
    ok( $content !~ /_REQUEST.*abc.*=.*123.*_SERVER/s &&
	$content =~ /_REQUEST.*foo.*array.*z.*3.*_SERVER/s,
	'$_REQUEST mimics $_GET' );
    ok( $content =~ /_SERVER = array/ &&
	$content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
    ok( $content =~ /_ENV = array/ &&
	$content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
    ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );


    # POST + query parameters
    $response = request POST 'http://localhost/vars.php?get=7&foo=14', [
	'foo[r]' => 's',
	'post' => 19,
	'foo[t]' => 'u',
	'foo[v]' => 'w',
    ];
    ok( $response, 'response post+get ok' );
    $content = eval { $response->content };

    ok( $content =~ /_GET = array.*get.*7.*_POST/s, '$_GET contains "get"' );
    ok( $content =~ /_REQUEST = array.*get.*7.*_SERVER/s,
	'$_REQUEST contains "get" from $_GET' );
    ok( $content =~ /_GET = array.*foo.*14.*_POST/s, '$_GET contains "foo"' );
    ok( $content !~ /_REQUEST = array.*foo.*14.*_SERVER/s, 
	'$_REQUEST doesn\'t contain "foo" from $_GET' );

    ok( $content =~ /_POST = array.*post.*19.*_REQUEST/s,
	'$_POST contains "post"' );
    ok( $content =~ /_POST = .*foo.*array.*r.*s.*_REQUEST/s &&
	$content =~ /_POST = .*foo.*array.*t.*u.*_REQUEST/s &&
	$content =~ /_POST = .*foo.*array.*v.*w.*_REQUEST/s,
	'$_POST contains array "foo"' );
    ok( $content =~ /_REQUEST = array.*post.*19.*_SERVER/s,
	'$_REQUEST contains "post"' );
    ok( $content =~ /_REQUEST = .*foo.*array.*r.*s.*_SERVER/s &&
	$content =~ /_REQUEST = .*foo.*array.*t.*u.*_SERVER/s &&
	$content =~ /_REQUEST = .*foo.*array.*v.*w.*_SERVER/s,
	'$_REQUEST contains array "foo"' );


    # added for v0.03 - parameter name with [] form a simple array
    $response = request POST 'http://localhost/vars.php?get=14&foo=77', [
	'foo[]' => '567',
	'post' => 36,
	'foo[]' => '789',
	'foo[]' => '678',
    ];
    ok( $response, 'response post+get ok' );
    $content = eval { $response->content };

    ok( $content =~ /_GET = array.*get.*14.*_POST/s, '$_GET contains "get"' );
    ok( $content =~ /_REQUEST = array.*get.*14.*_SERVER/s,
	'$_REQUEST contains "get" from $_GET' );
    ok( $content =~ /_GET = array.*foo.*77.*_POST/s, '$_GET contains "foo"' );
    ok( $content !~ /_REQUEST = array.*foo.*77.*_SERVER/s, 
	'$_REQUEST doesn\'t contain "foo" from $_GET' );

    ok( $content =~ /_POST = array.*post.*36.*_REQUEST/s,
	'$_POST contains "post"' );
    ok( $content =~ /_POST = .*foo.*array.*0.*567.*_REQUEST/s &&
	$content =~ /_POST = .*foo.*array.*1.*789.*_REQUEST/s &&
	$content =~ /_POST = .*foo.*array.*2.*678.*_REQUEST/s,
	'$_POST contains array "foo"' );
    ok( $content =~ /_REQUEST = array.*post.*36.*_SERVER/s,
	'$_REQUEST contains "post"' );
    ok( $content =~ /_REQUEST = .*foo.*array.*0.*567.*_SERVER/s &&
	$content =~ /_REQUEST = .*foo.*array.*2.*678.*_SERVER/s &&
	$content =~ /_REQUEST = .*foo.*array.*1.*789.*_SERVER/s,
	'$_REQUEST contains array "foo"' );

}

done_testing();
