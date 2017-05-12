#!perl -T

use Test::More tests => 10;
use Test::NoWarnings;
use Test::Exception;

my $CLASS;
BEGIN { $CLASS = 'App::Toodledo'; use_ok( $CLASS ) }

my $todo;
my @ATTRIBS = qw(user_id password key session_key);
my @METHODS = qw(get_session_token get_session_token_from_rc);
lives_ok { $todo = $CLASS->new( app_id => 'MyApp' ) };
isa_ok $todo, $CLASS;
can_ok $todo, $_ for @ATTRIBS;
can_ok $todo, $_ for @METHODS;
