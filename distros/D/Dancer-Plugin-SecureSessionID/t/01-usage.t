#!perl -w
use strict;
use Dancer::ModuleLoader;
use Test::More import => ['!pass'];

plan tests => 1;

{
    package Webservice;
    use Dancer;
    use Dancer::Plugin::SecureSessionID;

    setting environment => 'testing';
	set session => 'Simple';

    use_secure_session_id;

    get '/' => sub { session->id };
}

use Dancer::Test;

response_content_like([ GET => '/' ], qr{^[A-Za-z0-9_-]{22}$}, 'is base64url');

