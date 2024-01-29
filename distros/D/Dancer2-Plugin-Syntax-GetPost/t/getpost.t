use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];
use Plack::Test;
use HTTP::Request::Common;

{
    package TestApp;

    use Dancer2;
    use Dancer2::Plugin::Syntax::GetPost;

    get_post '/form' => sub { return "method = " . request->method };

    1;
}

my $app = Plack::Test->create( TestApp->to_app );

my $res = $app->request( GET '/form' );
is( $res->code, 200, 'GET /form exists' );
like( $res->content, qr/method = GET/, 'GET content matches expected output' );

$res = $app->request( POST '/form' );
is( $res->code, 200, 'POST /form exists' );
like( $res->content, qr/method = POST/, 'POST content matches expected output' );

$res = $app->request( PUT '/form' );
is( $res->code, 404, 'PUT /form does not exist' );

done_testing;
#
# This file is part of Dancer2-Plugin-Syntax-GetPost
#
# This software is Copyright (c) 2023 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
