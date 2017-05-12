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

    my $z1 = sprintf "VAR%08x", rand(0x7FFFFFFF);
    my $z2 = sprintf "VAL%08x", rand(0x7FFFFFFF);
    $ENV{$z1} = $z2;

    my $response = request('http://localhost/vars.php');
    ok( $response, 'response no params ok' );
    my $content = eval { $response->content };
    my ($env) = $content =~ /\$_ENV = array *\((.*)\)\s*\$_COOKIE/s;
    my @env = split /\n/, $env;

#   diag join("\n", sort @env);

    my $key_count = 0;
    while (my ($k,$v) = each %ENV) {
	$key_count++;
	next if $v =~ /\n/;
	ok( grep(/\Q$k\E.*=>.*\Q$v\E/,@env), "ENV $k ok" );
    }
    ok( $key_count > 2, "at least some env vars found ($key_count)" );
}

done_testing();
