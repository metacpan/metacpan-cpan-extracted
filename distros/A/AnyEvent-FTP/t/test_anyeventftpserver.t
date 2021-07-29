use Test2::V0 -no_srand => 1;
use Test::AnyEventFTPServer;
use File::chdir;

global_timeout_ok;

subtest 'basic' => sub {

  my $server = create_ftpserver_ok;
  isa_ok $server, 'AnyEvent::FTP::Server';
  isa_ok $server->test_uri, 'URI';

  my $client = $server->connect_ftpclient_ok;
  isa_ok $client, 'AnyEvent::FTP::Client';

  my $response = $client->help->recv;
  is $response->code, 214, "help response code = 214";

  $response = $client->quit->recv;
  is $response->code, 221, "quit response code = 221";

  $server->help_coverage_ok;

  $server->command_ok('bogus')
         ->code_is(500)
         ->code_like(qr{5..})
         ->message_like(qr{not understood});

  $server->command_ok('HELP')
         ->code_is(214)
         ->code_like(qr{.1.})
         ->message_like(qr{The following commands are recognized});

  isa_ok $server->res, 'AnyEvent::FTP::Client::Response';
};

subtest 'content_is' => sub {

  my $server = create_ftpserver_ok('FSRO');

  $server->command_ok('CWD' => "$CWD/corpus/nlst");

  $server->nlst_ok;
  $server->content_is("one.txt\nthree.txt\ntwo.txt\n");

  is(
    intercept { $server->content_is("one.txt\nthree.txt\ntwo.txt\n") },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'content matches';
      };
      end;
    },
    'pass okay',
  );

  is(
    intercept { $server->content_is("one.txt\ntwo.txt\nthree.txt\n") },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'content matches';
      };
      event Diag => sub {};
      event Diag => sub { call message => 'content:' };
      event Diag => sub { call message => '  one.txt' };
      event Diag => sub { call message => '  three.txt' };
      event Diag => sub { call message => '  two.txt' };
      event Diag => sub { call message => 'expected:' };
      event Diag => sub { call message => '  one.txt' };
      event Diag => sub { call message => '  two.txt' };
      event Diag => sub { call message => '  three.txt' };
      end;
    },
    'pass okay',
  );

  todo 'testing todo' => sub {
    $server->content_is("one.txt\ntwo.txt\nthree.txt\n");
  };

};

done_testing;
