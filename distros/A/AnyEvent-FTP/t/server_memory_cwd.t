use strict;
use warnings;
use autodie;
use Test::More tests => 20;
use Test::AnyEventFTPServer;
use AnyEvent::FTP::Server::Context::Memory;

AnyEvent::FTP::Server::Context::Memory->store->{top} = {
  foo => { bar => { stuff => { things => '' }} },
  bar => {},
  baz => 'stuff',
};

my $t = create_ftpserver_ok('Memory');

my $context;
$t->on_connect(sub { $context = shift->context });

# force a connect
$t->command_ok('NOOP')
  ->code_is(200);

is $context->cwd, "/", "cwd = /";

$t->command_ok(CWD => "/top")
  ->code_is(250);

is $context->cwd, "/top", "cwd = /top";

$t->command_ok(CWD => "foo/bar/stuff")
  ->code_is(250);

is $context->cwd, "/top/foo/bar/stuff", "cwd = /top/foo/bar/stuff";

$t->command_ok(CWD => "lameo")
  ->code_is(550);

$t->command_ok(CWD => "/lameo")
  ->code_is(550);

$t->command_ok(CWD => "../..")
  ->code_is(250);

is $context->cwd, "/top/foo", "cwd = /top/foo";

$t->command_ok(CWD => "./../../../../../top/./foo/.//./bar/./stuff")
  ->code_is(250);

is $context->cwd, "/top/foo/bar/stuff", "cwd = /top/foo/bar/stuff";
