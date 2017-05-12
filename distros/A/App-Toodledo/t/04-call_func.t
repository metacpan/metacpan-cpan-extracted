#!perl -T
use strict;
use warnings;

use Test::More tests => 7;
use Test::NoWarnings;
use Test::Exception;
use Test::MockModule;
use Test::MockObject;
use JSON;

use Log::Log4perl qw(:easy);

my $CLASS;
my $FUNC    = 'myFunc';
my $SUBFUNC = 'mySubFunc';
my $USERID  = 'username';
my $APPID   = 'myApp';

BEGIN { Log::Log4perl->easy_init( $OFF );
        $CLASS = 'App::Toodledo';
        use_ok $CLASS }

my $mock = Test::MockModule->new( $CLASS );
my $fake_a = Test::MockObject->new;
$mock->mock( _make_user_agent => sub { $fake_a } );
my $todo = $CLASS->new( app_id => $APPID, user_agent => $fake_a );

my $url;
my $fake_r = Test::MockObject->new;
my $code = 543;
$fake_r->mock( code => sub { $code } );
$fake_a->mock( post => sub { $url = $_[1]; $fake_r } );

throws_ok { $todo->call_func( $FUNC, $SUBFUNC ) } qr/contact/;

$code = 200;
my $content = encode_json( { errorCode => 500 } );
$fake_r->mock( content => sub { $content } );
throws_ok { $todo->call_func( $FUNC, $SUBFUNC ) } qr/offline/;
like $url, qr!$FUNC/$SUBFUNC!;

$content = encode_json( { foo => 'bar' } );
my $ref;
lives_ok { $ref = $todo->call_func( $FUNC, $SUBFUNC ) };
ok eq_hash( { foo => 'bar' }, $ref );
