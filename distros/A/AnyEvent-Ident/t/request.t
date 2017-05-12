use strict;
use warnings;
use Test::More tests => 8;
use AnyEvent::Ident::Request;

do {
  my $req = eval { AnyEvent::Ident::Request->new(" 44 , 33 ") };
  diag $@ if $@;
  isa_ok $req, 'AnyEvent::Ident::Request';
  
  is eval { $req->server_port }, 44, "server_port = 44";
  diag $@ if $@;
  is eval { $req->client_port }, 33, "client_port = 33";
  diag $@ if $@;
  is eval { $req->as_string }, " 44 , 33 ", "as_string";
  diag $@ if $@;
};

do {
  my $req = eval { AnyEvent::Ident::Request->new(44, 33) };
  diag $@ if $@;
  diag $@ if $@;
  isa_ok $req, 'AnyEvent::Ident::Request';
  
  is eval { $req->server_port }, 44, "server_port = 44";
  diag $@ if $@;
  is eval { $req->client_port }, 33, "client_port = 33";
  diag $@ if $@;
  is eval { $req->as_string }, "44,33", "as_string";
  diag $@ if $@;
};