#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');

use Test::More tests => 5;
use Catalyst::Test 'TestApp';

SKIP: {
    eval { require Catalyst::Plugin::Static::Simple };
    skip 'Catalyst::Plugin::Static::Simple required for this test', 5 if $@;

    TestApp->setup(qw/Static::Simple/);

    my $image_fn = 'cpan.jpg';
    my $image    =
      File::Spec->catfile( $FindBin::Bin, qw/lib TestApp root/, 'cpan.jpg' );

    # normal requests
    ok( my $res = request("http://localhost/sendfile/$image_fn"),
        'request ok' );
    is( $res->header('X-LIGHTTPD-send-file'),
        $image_fn, 'correct sendfile header' );

    # lighty emuration
    {
        local $ENV{CATALYST_ENGINE} = 'HTTP';
        ok( $res = request("http://localhost/sendfile_emuration/$image_fn"),
            'request ok' );
        is( $res->content_type, 'image/jpeg', 'content_type ok' );
        is( $res->content_length, -s $image, 'content_length ok' );
    }
}
