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

subtest 'root' => sub {
    my $res = $test->request( GET '/' );
    like(
        $res->content,qr/Hello World/,'Get content for /'
    );
};

done_testing;

