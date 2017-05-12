use strict;
use warnings;
use autodie;
use Test::More tests => 12;
use Test::AnyEventFTPServer;
use Path::Class::Dir;
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

$t->command_ok('CDUP')
  ->code_is(250);

is $context->cwd, "/", "cwd = /";

$context->cwd(Path::Class::Dir->new_foreign('Unix', '/top/foo/bar/stuff'));

$t->command_ok('CDUP')
  ->code_is(250);

is $context->cwd, "/top/foo/bar", "cwd = /top/foo/bar";

$context->cwd(Path::Class::Dir->new_foreign('Unix', '/bogus/directory'));

$t->command_ok('CDUP')
  ->code_is(550);
