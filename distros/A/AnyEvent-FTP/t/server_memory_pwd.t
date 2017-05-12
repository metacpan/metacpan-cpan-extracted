use strict;
use warnings;
use autodie;
use Test::More tests => 9;
use Test::AnyEventFTPServer;
use Path::Class::Dir;
use AnyEvent::FTP::Server::Context::Memory;

my $t = create_ftpserver_ok('Memory');

my $context;
$t->on_connect(sub { $context = shift->context });

# force a connect
$t->command_ok('NOOP')
  ->code_is(200);

$t->command_ok('PWD')
  ->code_is(257)
  ->message_is('"/" is the current directory');

$context->cwd(Path::Class::Dir->new_foreign("Unix", '', qw( foo bar baz )));

$t->command_ok('PWD')
  ->code_is(257)
  ->message_is('"/foo/bar/baz" is the current directory');
