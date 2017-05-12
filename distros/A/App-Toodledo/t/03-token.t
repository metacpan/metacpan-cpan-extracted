#!perl -T
use strict;
use warnings;

use Test::More tests => 6;
use Test::NoWarnings;
use Test::Exception;
use Test::MockModule;
use Test::MockObject;
use File::Spec;
use File::HomeDir qw(my_home);

my $CLASS;
my $USERID   = 'username';
my $APPID    = 'myapp';
my $TOKEN    = 'XYZZY';
my $APPTOKEN = 'PLUGH';

BEGIN { $CLASS = 'App::Toodledo'; use_ok $CLASS }

my $todo = $CLASS->new( app_id => $APPID, user_id => $USERID );

my ($token, $new_session_token_called);
my $mock = Test::MockModule->new( $CLASS );
$mock->mock( app_token_of => sub { $APPTOKEN } );
my $mockt = Test::MockModule->new( 'App::Toodledo::TokenCache' );
my $cache_file;
my $fake_t = Test::MockObject->new;
my $fake_i = Test::MockObject->new;
$fake_t->mock( valid_token => sub { $fake_i } );
$fake_i->mock( token => sub { $TOKEN } );
$mockt->mock( new_from_file => sub { $cache_file = shift; $fake_t } );

my $result;
lives_ok{ $result = $todo->get_session_token_from_rc };

is $result, $TOKEN, 'Result';
isa_ok $cache_file, 'App::Toodledo::TokenCache';
my $homedir = my_home();
is $todo->_token_cache_name, File::Spec->catfile( $homedir,
						  $todo->Token_File_Name ),
  'Token file name';
