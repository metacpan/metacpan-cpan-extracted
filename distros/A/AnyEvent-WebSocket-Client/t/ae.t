use strict;
use warnings;
BEGIN { eval q{ use EV } }
use AnyEvent::WebSocket::Client;
use Test::More;
use FindBin ();
use lib $FindBin::Bin;
use testlib::Server;

testlib::Server->set_timeout;

my $counter;
my $max;
my $last_handshake;

my $uri = testlib::Server->start_server(
  customize_server_response => sub {
    my($handshake) = @_;
    if($handshake->req->subprotocol)
    {
      note "sub protocols requested: @{[ $handshake->req->subprotocol ]}";
      my %sb = map { $_ => 1 } split(/,/, $handshake->req->subprotocol);
      if($sb{bar})
      {
        $handshake->res->subprotocol('bar');
      }
      if($sb{klingon})
      {
        $handshake->res->subprotocol('romulan');
      }
    }
  },

  handshake => sub {  # handshake
    my $opt = { @_ };
    $counter = 1;
    $max = 15;
    note "max = $max";
    $last_handshake = $opt->{handshake};
    #note $opt->{handshake}->req->to_string;
    #note $opt->{handshake}->to_string;
    note "resource = " . $opt->{handshake}->req->resource_name;
    note "version  = " . $opt->{handshake}->version;
    if($opt->{handshake}->req->resource_name =~ /\/count\/(\d+)/)
    { $max = $1 }
    note "max = $max";
  },

  message => sub {  # message
    my $opt = { @_ };
    eval q{
      note "send $counter";
      $opt->{hdl}->push_write($opt->{frame}->new($counter++)->to_bytes);
      if($counter >= $max)
      {
        $opt->{hdl}->push_write($opt->{frame}->new(type => 'close')->to_bytes);
        $opt->{hdl}->push_shutdown;
      }
    };
  },
);

$uri->path('/count/10');
note $uri;

subtest basic => sub {

  my $connection = AnyEvent::WebSocket::Client->new->connect($uri)->recv;
  isa_ok $connection, 'AnyEvent::WebSocket::Connection';

  my $done = AnyEvent->condvar;

  $connection->send('ping');

  my $last;

  $connection->on(each_message => sub {
    my $message = pop->body;
    note "recv $message";
    $connection->send('ping');
    $last = $message;
  });

  $connection->on(finish => sub {
    $done->send(1);
  });

  is $done->recv, '1', 'friendly disconnect';

  is $last, 9, 'last = 9';
};

subtest 'version' => sub {

  my $connection = AnyEvent::WebSocket::Client->new(
    protocol_version => 'draft-ietf-hybi-10',
  )->connect($uri)->recv;

  is $last_handshake->version, 'draft-ietf-hybi-10', 'server side protool_version = draft-ietf-hybi-10';
};

subtest 'subprotocol' => sub {

  is_deeply(
    AnyEvent::WebSocket::Client->new( subprotocol => ['foo','bar','baz'] )->subprotocol,
    ['foo','bar','baz'],
  );

  is_deeply(
    AnyEvent::WebSocket::Client->new( subprotocol => ['foo'] )->subprotocol,
    ['foo'],
  );

  is_deeply(
    AnyEvent::WebSocket::Client->new( subprotocol => 'foo' )->subprotocol,
    ['foo'],
  );
  
  my $connection = AnyEvent::WebSocket::Client->new(subprotocol => ['foo','bar','baz'])->connect($uri)->recv;  
  is($last_handshake->res->subprotocol, 'bar', 'server agreed to bar');
  is($connection->subprotocol, 'bar', 'connection also has bar');

  eval { AnyEvent::WebSocket::Client->new(subprotocol => ['foo','baz'])->connect($uri)->recv };
  my $error = $@;
  like $error, qr{no subprotocol in response}, 'bad protocol throws an exception';

  eval { AnyEvent::WebSocket::Client->new(subprotocol => ['klingon','cardasian'])->connect($uri)->recv };
  $error = $@;
  like $error, qr{subprotocol mismatch, requested: klingon, cardasian, got: romulan}, 'bad protocol throws an exception';

};

subtest http_headers => sub {

  is_deeply(
    AnyEvent::WebSocket::Client->new( http_headers => { 'X-Foo' => 'bar', 'X-Baz' => [ 'abc', 'def' ] } )->http_headers,
    [ 'X-Baz' => 'abc',
      'X-Baz' => 'def',
      'X-Foo' => 'bar', ]
  );

  my $client = AnyEvent::WebSocket::Client->new( http_headers => [ 'X-Foo' => 'bar', 'X-Baz' => 'abc', 'X-Baz' => 'def' ] );

  is_deeply(
    $client->http_headers,
    [  'X-Foo' => 'bar', 
       'X-Baz' => 'abc', 
       'X-Baz' => 'def',  ]
  );
  
  # Note: Protocol::WebSocket does not currently support headers with multiple instances of the same
  # key, so we just won't test that.
  $client = AnyEvent::WebSocket::Client->new( http_headers => [ 'X-Foo' => 'bar', 'X-Baz' => 'abc' ] );
  my $connection = $client->connect($uri)->recv;

  is($last_handshake->req->fields->{'x-foo'}, 'bar');
  is($last_handshake->req->fields->{'x-baz'}, 'abc');

};

done_testing;
