#!perl -w

my $fcgi;

use CGI::Fast;
use Test::More tests => 15;

# Shut up "used only once" warnings.
() = $CGI::Q;

ok( my $q = CGI::Fast->new(), 'created new CGI::Fast object' );
is( $q, $CGI::Q, 'checking to see if the object was stored properly' );
is( $q->param(), (), 'no params' );

ok( $q = CGI::Fast->new({ foo => 'bar' }), 'creating object with params' );
is( $q->param('foo'), 'bar', 'checking passed param' );

is($CGI::HEADERS_ONCE,0, "reality check default value for CGI::HEADERS_ONCE++");
import CGI::Fast '-unique_headers';
CGI::Fast->new;
is($CGI::HEADERS_ONCE,1, "pragma in subclass set package variable in parent class. ");
$q = CGI::Fast->new({ a => 1 });
ok($q, "reality check: something was returned from CGI::Fast->new besides undef");
is($CGI::HEADERS_ONCE,1, "package variable in parent class persists through multiple calls to CGI::Fast->new ");

# overloaded argument testing

my $initializer = 'something';
ok( $q = CGI::Fast->new($initializer),'initializer as first arg' );

no warnings 'redefine';
no warnings 'prototype';
*FCGI::Accept = sub { 1 };

ok( $q = CGI::Fast->new(),'no constructor args' );
ok( $q = CGI::Fast->new( sub {} ),'hook as first arg' );
ok( $q = CGI::Fast->new( sub {},"anything" ),'CGI::Fast' );
ok( $q = CGI::Fast->new( sub {},"anything",0 ),'CGI::Fast' );
ok( $q = CGI::Fast->new( sub {},"anything",0,$initializer ),'CGI::Fast' );
