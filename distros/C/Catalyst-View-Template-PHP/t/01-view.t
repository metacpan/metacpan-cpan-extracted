use FindBin;
use lib "$FindBin::Bin/lib";
use strict;
use warnings;
use Test::More;
# use Catalyst::Test 'TestApp';

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

TODO: {

    ok('XXX','make some requests to the test application');
    ok('XXX','verify request was successful');
    ok('XXX','verify the output');

}

done_testing();
