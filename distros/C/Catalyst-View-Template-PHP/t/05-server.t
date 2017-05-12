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

sub array {
    return { @_ };
}

{
    my $response = request('http://localhost/vars.php');
    ok( $response, 'response no params ok' );
    my $content = eval { $response->content };
    my ($server) = $content =~ /\$_SERVER = array *\((.*)\)\s*\$_ENV/s;
    my @server = split /\n/, $server;

    ok( (grep { /SERVER_NAME.*localhost/ } @server), '$_SERVER[SERVER_NAME] ok' );
    ok( (grep { /REQUEST_METHOD.*GET/ } @server), '$_SERVER[REQUEST_METHOD] ok' );
    ok( (grep { /REQUEST_URI.*vars.php/ } @server), '$_SERVER[REQUEST_URI] ok' );
}

done_testing();
