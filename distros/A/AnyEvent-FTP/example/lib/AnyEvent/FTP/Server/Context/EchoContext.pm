package AnyEvent::FTP::Server::Context::EchoContext;
 
use Moo;
 
extends 'AnyEvent::FTP::Server::Context';
with 'AnyEvent::FTP::Server::Role::Help';
 
# implement the non-existent echo command
sub help_echo { 'ECHO <SP> text' }
 
sub cmd_echo
{
  my($self, $con, $req) = @_;
  $con->send_response(211 => $req->args);
  $self->done;
}

1;
