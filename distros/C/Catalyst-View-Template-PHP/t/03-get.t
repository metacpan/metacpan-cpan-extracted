use FindBin;
use lib "$FindBin::Bin/lib";
use strict;
use warnings;
use Test::More;
use Catalyst::Test 'TestApp';
use Data::Dumper;

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
    ok( $response, 'response ok' );
    my $content = eval { $response->content };
    ok( $content =~ /_GET = array *\(\s*\)/, '$_GET is empty' );
    ok( $content =~ /_POST = array *\(\s*\)/, '$_POST is empty' );
    ok( $content =~ /_REQUEST = array *\(\s*\)/, '$_REQUEST is empty' );
    ok( $content =~ /_SERVER = array/ &&
	$content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
    ok( $content =~ /_ENV = array/ &&
	$content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
    ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );


    $response = request('http://localhost/vars.php?abc=123&def=456');
    ok( $response, 'response ok' );
    $content = eval { $response->content };
    ok( $content !~ /_GET = array *\(\s*\)/, '$_GET not empty' );
    ok( $content =~ /_GET.*abc.*=.*123.*_POST/s, '$_GET["abc"] ok');
    ok( $content =~ /_GET.*def.*=.*456.*_POST/s, '$_GET["def"] ok');
    ok( $content =~ /_POST = array *\(\s*\)/, '$_POST is empty' );
    ok( $content !~ /_REQUEST = array *\(\s*\)/, '$_REQUEST not empty' );
    ok( $content =~ /_REQUEST.*abc.*=.*123.*_SERVER/s &&
	$content =~ /_REQUEST.*def.*=.*456.*_SERVER/s, '$_REQUEST mimics $_GET' );
    ok( $content =~ /_SERVER = array/ &&
	$content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
    ok( $content =~ /_ENV = array/ &&
	$content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
    ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );


    # When PHP receives a duplicate param name, it ignores all values
    # except the last value.
    $response = request('http://localhost/vars.php?abc=123&def=456&abc=789');
    ok( $response, 'response ok' );
    $content = eval { $response->content };
    ok( $content !~ /_GET = array *\(\s*\)/, '$_GET not empty' ); 
    ok( $content !~ /_GET.*abc.*=.*123.*_POST/s, 'lost first val for $_GET["abc"]');
    ok( $content =~ /_GET.*abc.*=.*789.*_POST/s, 'got last val for $_GET["abc"]');
    ok( $content =~ /_GET.*def.*=.*456.*_POST/s, '$_GET["def"] ok');
    ok( $content =~ /_POST = array *\(\s*\)/, '$_POST is empty' );
    ok( $content !~ /_REQUEST = array *\(\s*\)/, '$_REQUEST not empty' );
    ok( $content !~ /_REQUEST.*abc.*=.*123.*_SERVER/s &&
	$content =~ /_REQUEST.*abc.*=.*789.*_SERVER/s &&
	$content =~ /_REQUEST.*def.*=.*456.*_SERVER/s, '$_REQUEST mimics $_GET' );
    ok( $content =~ /_SERVER = array/ &&
	$content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
    ok( $content =~ /_ENV = array/ &&
	$content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
    ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );


    # When PHP receives a param name like  foo[bar] , it creates an 
    # associative array param named foo with key bar.
    $response = request('http://localhost/vars.php?foo[x]=1&foo[y]=2&foo[z]=3');
    ok( $response, 'response ok' );
    $content = eval { $response->content };
    ok( $content !~ /_GET = array *\(\s*\)/, '$_GET not empty' ); 
    my $z = $content =~ /_GET.*foo(.*)\$_POST/s;
    my $foo = $1;
    ok( $z, '$_GET["foo"] was set' );
    ok( $foo =~ /array/, '$_GET["foo"] was set to a PHP array' );
    ok( $foo =~ /x.*1/, '$_GET["foo"]["x"] was set' );
    ok( $foo =~ /y.*2/, '$_GET["foo"]["y"] was set' );
    ok( $foo =~ /z.*3/, '$_GET["foo"]["z"] was set' );
    ok( $content =~ /_POST = array *\(\s*\)/, '$_POST is empty' );
    ok( $content !~ /_REQUEST = array *\(\s*\)/, '$_REQUEST not empty' );
    ok( $content !~ /_REQUEST.*abc.*=.*123.*_SERVER/s &&
	$content =~ /_REQUEST.*foo.*array.*z.*3.*_SERVER/s,
	'$_REQUEST mimics $_GET' );
    ok( $content =~ /_SERVER = array/ &&
	$content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
    ok( $content =~ /_ENV = array/ &&
	$content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
    ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );
}

done_testing();
