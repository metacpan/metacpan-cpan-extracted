use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];

use Dancer2;
use Dancer2::Test;
use Dancer2::Plugin::Syntax::GetPost;

get_post '/form' => sub { return "method = " . request->method };

route_exists [ GET => '/form' ];
route_exists [ POST => '/form' ];
route_doesnt_exist [ PUT => '/form' ];
response_content_like [ GET => '/form' ], qr/method = GET/;
response_content_like [ POST => '/form' ], qr/method = POST/;

done_testing;
#
# This file is part of Dancer2-Plugin-Syntax-GetPost
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
