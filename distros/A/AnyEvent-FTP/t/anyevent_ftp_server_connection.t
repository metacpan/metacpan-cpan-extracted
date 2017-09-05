use 5.010;
use Test2::V0 -no_srand => 1;
use AnyEvent::FTP::Server::Connection;

eval q{
  package Context;
  
  use Moo;
  
  with 'AnyEvent::FTP::Server::Role::Context';

  sub push_request
  {
    my $sub = delete shift->{cb};
    $sub->(@_) if $sub;
  }  
};
die $@ if $@;

my $cx = eval { Context->new };
diag $@ if $@;
isa_ok $cx, 'Context';

my $con = eval { AnyEvent::FTP::Server::Connection->new( context => $cx, ip => '1.2.3.4' ) };
diag $@ if $@;
isa_ok $con, 'AnyEvent::FTP::Server::Connection';

my $check_user_foo = sub {
  my($con, $req) = @_;
  
  isa_ok $con, 'AnyEvent::FTP::Server::Connection';
  isa_ok $req, 'AnyEvent::FTP::Request';
  is eval { $req->command }, 'USER', 'cmd = USER';
  diag $@ if $@;
  is eval { $req->args }, 'foo',  'arg = foo';
  diag $@ if $@;
};

$cx->{cb} = $check_user_foo;

isa_ok eval { $con->process_request("USER foo\015\012") }, 'AnyEvent::FTP::Server::Connection';
diag $@ if $@;

$cx->{cb} = $check_user_foo;

isa_ok eval { $con->process_request("user foo\015\012") }, 'AnyEvent::FTP::Server::Connection';
diag $@ if $@;

$cx->{cb} = sub {
  my($con, $req) = @_;
  
  isa_ok $con, 'AnyEvent::FTP::Server::Connection';
  isa_ok $req, 'AnyEvent::FTP::Request';
  is eval { $req->command }, 'PWD', 'cmd = PWD';
  diag $@ if $@;
  is eval { $req->args }, '',  'arg = ""';
  diag $@ if $@;
};

isa_ok eval { $con->process_request("pWd\015\012") }, 'AnyEvent::FTP::Server::Connection';
diag $@ if $@;

done_testing;
