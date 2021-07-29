use Test2::V0 -no_srand => 1;
use AnyEvent::FTP::Server::Role::Type;
use 5.010;
use Test::AnyEventFTPServer;

eval {
  package
    AnyEvent::FTP::Server::Context::TestContext;

  use Moo;  ## no critic (Modules::ProhibitConditionalUseStatements)
  extends 'AnyEvent::FTP::Server::Context';
  with 'AnyEvent::FTP::Server::Role::Type';
  with 'AnyEvent::FTP::Server::Role::Auth';
  with 'AnyEvent::FTP::Server::Role::Help';

  sub cmd_gt
  {
    my($self, $con, $req) = @_;
    $con->send_response(211 => $self->type);
    $self->done;
  }

  1;
  $INC{'AnyEvent/FTP/Server/Context/TestContext.pm'} = __FILE__;
};
die $@ if $@;

my $t = create_ftpserver_ok('TestContext');

$t->command_ok('GT')
  ->message_like(qr{A});

$t->command_ok('TYPE')
  ->code_is(500)
  ->message_like(qr{Type not understood});

$t->command_ok('GT')
  ->message_like(qr{A});

$t->command_ok(TYPE => 'I')
  ->code_is(200)
  ->message_like(qr{Type set to I});

$t->command_ok('GT')
  ->message_like(qr{I});

$t->command_ok(TYPE => 'A')
  ->code_is(200)
  ->message_like(qr{Type set to A});

$t->command_ok('GT')
  ->message_like(qr{A});

done_testing;
