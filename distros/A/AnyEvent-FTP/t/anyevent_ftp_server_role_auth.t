use Test2::V0 -no_srand => 1;
use AnyEvent::FTP::Server::Role::Auth;
use 5.010;
use Test::AnyEventFTPServer;

eval {
  package
    AnyEvent::FTP::Server::Context::TestContext;

  use Moo;  ## no critic (Modules::ProhibitConditionalUseStatements)
  extends 'AnyEvent::FTP::Server::Context';
  with 'AnyEvent::FTP::Server::Role::Auth';
  with 'AnyEvent::FTP::Server::Role::Help';

  has '+unauthenticated_safe_commands' => (
    default => sub { [ qw( USER PASS HELP QUIT FOO ) ] },
  );

  sub cmd_foo
  {
    my($self, $con, $req) = @_;
    $con->send_response(211 => 'Here to stay');
    $self->done;
  }

  sub cmd_bar
  {
    my($self, $con, $req) = @_;
    $con->send_response(211 => 'And another thing');
    $self->done;
  }

  1;
  $INC{'AnyEvent/FTP/Server/Context/TestContext.pm'} = __FILE__;
};
die $@ if $@;

my $t = create_ftpserver_ok('TestContext');
$t->auto_login(0);

$t->on_connect(sub {
  shift->context->bad_authentication_delay(0);
});

$t->command_ok('FOO')
  ->code_is(211);
$t->command_ok('BAR')
  ->code_is(530);

$t->command_ok('PASS', 'rubbish')
  ->code_is(503);

$t->command_ok('USER')
  ->code_is(530);

my($user, $pass) = split /:/, $t->test_uri->userinfo;
$t->command_ok('USER', $user)
  ->code_is(331);

$t->command_ok('PASS', 'bogus')
  ->code_is(530);

$t->command_ok('USER', $user)
  ->code_is(331);

$t->command_ok('PASS', $pass)
  ->code_is(230);

$t->command_ok('FOO')
  ->code_is(211);
$t->command_ok('BAR')
  ->code_is(211);

$t->help_coverage_ok('AnyEvent::FTP::Server::Role::Auth');

done_testing;
