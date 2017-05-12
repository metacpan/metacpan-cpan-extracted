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

    my $response = request('http://localhost/');
    ok( $response, 'response ok' );
    ok( $response->content =~ /matched TestApp/ , 'content ok' );

    # let's do a trivial request

    $response = request( 'http://localhost/hello.php' );
    ok( $response, 'trivial response ok' );
    ok( $response->content =~ /hello\W+world/i , 'trivial content ok' );

    $response = request( 'http://localhost/phpinfo.php' );
    ok( $response, 'phpinfo response ok' );
    my $content = $response->content;
    ok( $content =~ /html.*head.*body/is , 'phpinfo response is HTML' );
    my ($version) = $content =~ /PHP Version (5\.\d+\.\d+)/;
    ok( $version, "phpinfo contains version ($version)" );
    ok( $content =~ /Directive.*Local Value.*Master Value/si,
	'phpinfo contains directive list' );
    if ($version && $version lt "5.4.0") { # removed in 5.4
	ok( $content =~ /magic_quotes_gpc/, 'phpinfo contains config data' );
    }
    ok( $content =~ /Variable.*Value/, 'phpinfo contains variable data' );
    ok( $content =~ /_SERVER/ && $content =~ /_ENV/,
	'phpinfo contains variable info' );


#   diag $response->content;

}

done_testing();
