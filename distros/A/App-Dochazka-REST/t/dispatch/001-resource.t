# ************************************************************************* 
# Copyright (c) 2014-2015, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 
#
# tests for Resource.pm
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $log $meta $site );
use App::CELL::Status;
use App::Dochazka::REST::Test;
use Data::Dumper;
use HTTP::Request::Common qw( GET PUT POST DELETE );
use JSON;
use Plack::Test;
use Scalar::Util qw( blessed );
use Test::Fatal;
use Test::JSON;
use Test::More;
use Test::Warnings;
use Web::MREST::Resource;

note( 'initialize, connect to database, and set up a testing plan' );
my $app = initialize_regression_test();
isnt( $app, undef );

note( 'instantiate Plack::Test object' );
my $test = Plack::Test->create( $app );
isa_ok( $test, 'Plack::Test::MockHTTP' );

my ( $res, $json );

note( 'the very basic-est request (200)' );
req( $test, 200, 'demo', 'GET', '/' );

note( 'a too-long request (414)' );
req( $test, 414, 'demo', 'GET', '/' x 1001 );

note( 'request for HTML' );
my $r = GET '/', 'Accept' => 'text/html';
isa_ok( $r, 'HTTP::Request' );
$r->authorization_basic( 'root', 'immutable' );
my $resp = $test->request( $r );
isa_ok( $resp, 'HTTP::Response' );
is( $resp->code, 200 );
like( $resp->content, qr/<html>/ );

note( 'request with bad credentials (401)' );
req( $test, 401, 'fandango', 'GET', '/' );

note( 'request that doesn\'t pass ACL check (403)' );
req( $test, 403, 'demo', 'GET', '/forbidden' );

note( 'GET request for non-existent resource (400)' );
req( $test, 400, 'demo', 'GET', '/HEE HAW!!!/non-existent/resource' );

note( 'PUT request for non-existent resource (400)' );
req( $test, 400, 'demo', 'PUT', '/HEE HAW!!!/non-existent/resource' );

note( 'POST request for non-existent resource (400)' );
req( $test, 400, 'demo', 'POST', '/HEE HAW!!!/non-existent/resource' );

note( 'DELETE request on non-existent resource (400)' );
req( $test, 400, 'demo', 'DELETE', '/HEE HAW!!!/non-existent/resource' );

note( 'test argument validation in \'push_onto_context\' method' );
like( exception { Web::MREST::Resource::push_onto_context( undef, 'DUMMY2' ); },
      qr/not one of the allowed types: hashref/ );
like( exception { Web::MREST::Resource::push_onto_context( undef, {}, ( 3..12 ) ); },
      qr/but 1 was expected/ );
like( exception { Web::MREST::Resource::push_onto_context(); },
      qr/0 parameters were passed.+but 1 was expected/ );

note( 'test if we can get the context' );
my $resource_self = bless {}, 'Web::MREST::Resource';
is_deeply( $resource_self->context, {} );
$resource_self->context( { 'bubba' => 'BAAAA' } );
is( $resource_self->context->{'bubba'}, 'BAAAA' );

note( 'test if the \'no_cache\' headers are present in each response' );
$r = GET '/', 'Accept' => 'application/json', 'Content_Type' => 'application/json';
isa_ok( $r, 'HTTP::Request' );
$r->authorization_basic( 'root', 'immutable' );
$resp = $test->request( $r );
isa_ok( $resp, 'HTTP::Response' );
is( $resp->header( 'Cache-Control' ), 'no-cache, no-store, must-revalidate, private' );
is( $resp->header( 'Pragma' ), 'no-cache' );

done_testing;
