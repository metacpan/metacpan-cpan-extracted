#perl

use strict;
use warnings;
use Test::More;
use Plack::Test;
use Dancer2;
use HTTP::Request::Common;
use HTTP::Cookies;
use lib File::Spec->catdir( 't' );

use t::lib::TestApp2;

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

subtest 'english' => sub {
    my $req = GET '/en'; 
    my $res = $test->request( $req );
    like(
        $res->content,qr/bye/,'Get content for /:lang where :lang is en'
    );
};

subtest 'spanish' => sub {
    my $req = GET '/es'; 
    my $res = $test->request( $req );
    like(
        $res->content,qr/chao/,'Get content for /:lang where :lang is es'
    );
};
done_testing;

