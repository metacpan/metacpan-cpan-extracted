#perl

use strict;
use warnings;
use Test::More;
use Plack::Test;
use Dancer2;
use HTTP::Request::Common;
use lib File::Spec->catdir( 't', 'lib' );

use t::lib::TestApp;

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

subtest 'getting a cart by default' => sub {
    my $res = $test->request( GET '/cart/new/' );
    like(
        $res->content,qr//,'Get content for /cart/new'
    );
};


done_testing;
