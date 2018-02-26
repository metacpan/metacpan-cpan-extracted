#!/usr/bin/env perl

use strict;
use warnings;

use Test::More import => ['!pass'];
use Test::Exception;
use Test::NoWarnings;

use strict;
use warnings;
use Dancer;
use Dancer::ModuleLoader;

BEGIN {
    plan tests => 11;
    use_ok 'Dancer::Session::Cookie'
}

my $session;

throws_ok { $session = Dancer::Session::Cookie->create }
    qr/session_cookie_key must be defined/, 'requires session_cookie_key';

set session_cookie_key => 'test/secret*@?)';
lives_and { $session = Dancer::Session::Cookie->create } 'works';
is $@, '', 'Cookie session created';

isa_ok $session, 'Dancer::Session::Cookie';
can_ok $session, qw(init create retrieve destroy flush);

my $value1 = $session->_cookie_value;
ok defined($value1), 'cookie value is defined';
$session->{bar} = 'baz';
my $value2 = $session->_cookie_value;
isnt $value2, $value1, "cookie value changed after storing data";
ok length($value2) > 20, 'length is a long string';

my $s = Dancer::Session::Cookie->retrieve($session->id);
is_deeply $s, $session, 'session is retrieved';

$s = Dancer::Session::Cookie->retrieve('XXX');
is $s, undef, 'unknown session is not found';

