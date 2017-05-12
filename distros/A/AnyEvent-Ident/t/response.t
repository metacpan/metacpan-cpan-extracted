use strict;
use warnings;
use Test::More tests => 30;
use AnyEvent::Ident::Request;
use AnyEvent::Ident::Response;

do {
  my $response = eval {
    AnyEvent::Ident::Response->new(
      "56192 , 113 : USERID : UNIX :optimus"
    );
  };
  diag $@ if $@;
  isa_ok $response, 'AnyEvent::Ident::Response';

  is eval { $response->as_string }, "56192 , 113 : USERID : UNIX :optimus", "as_string";
  diag $@ if $@;
  
  is $response->server_port, '56192',     'server_port = 56192';
  is $response->client_port, '113',       'client_port = 113';
  is $response->username,    'optimus',   'username = optimus';
  is $response->os,          'UNIX',      'os = UNIX';
  is $response->_key,        '56192:113', '_key = 56192:113';

  ok $response->is_success, "is_success (true)";
};

do {
  my $req = AnyEvent::Ident::Request->new(56192, 113);
  my $response = eval {
    AnyEvent::Ident::Response->new(
      req      => $req,
      username => 'optimus',
      os       => 'UNIX',
    );
  };
  diag $@ if $@;
  isa_ok $response, 'AnyEvent::Ident::Response';
  
  is eval { $response->as_string }, "56192,113:USERID:UNIX:optimus", "as_string";
  diag $@ if $@;
  
  is $response->server_port, '56192',     'server_port = 56192';
  is $response->client_port, '113',       'client_port = 113';
  is $response->username,    'optimus',   'username = optimus';
  is $response->os,          'UNIX',      'os = UNIX';
  is $response->_key,        '56192:113', '_key = 56192:113';

  ok $response->is_success, "is_success (true)";
};

do {
  my $response = eval {
    AnyEvent::Ident::Response->new(
      "42128 , 56192 : ERROR : NO-USER"
    );
  };
  diag $@ if $@;
  isa_ok $response, 'AnyEvent::Ident::Response';

  is eval { $response->as_string }, "42128 , 56192 : ERROR : NO-USER", "as_string";
  diag $@ if $@;

  is $response->server_port, '42128',       'server_port = 42128';
  is $response->client_port, '56192',       'client_port = 56192';
  is $response->error_type,  'NO-USER',     'error_type = NO-USER';
  is $response->_key,        '42128:56192', '_key = 42128:56192';
  
  ok !$response->is_success, "is_success (false)";
};

do {
  my $req = AnyEvent::Ident::Request->new(42128, 56192);
  my $response = eval {
    AnyEvent::Ident::Response->new(
      req => $req,
      error_type => 'NO-USER',
    );
  };
  diag $@ if $@;
  isa_ok $response, 'AnyEvent::Ident::Response';

  is eval { $response->as_string }, "42128,56192:ERROR:NO-USER", "as_string";
  diag $@ if $@;

  is $response->server_port, '42128',       'server_port = 42128';
  is $response->client_port, '56192',       'client_port = 56192';
  is $response->error_type,  'NO-USER',     'error_type = NO-USER';
  is $response->_key,        '42128:56192', '_key = 42128:56192';
  
  ok !$response->is_success, "is_success (false)";
};