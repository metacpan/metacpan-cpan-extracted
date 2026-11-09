use strict;
use warnings;
use Test::More;

use DBIO::Test::Future ();
use DBIO::Storage::Async;

# karr k392 (1) -- the error of the listen connection is a text about a
# connection made from the connect info, so it never quotes the connect
# info's credentials, as the pool's connect error does not (ADR 0025
# addendum). Both texts a failed listen builds -- the open and the
# LISTEN/UNLISTEN -- reach the on_listen_error hook and the Future masked.

{
  package K392::Transport;
  use base 'DBIO::Storage::Async';
  sub future_class           { 'DBIO::Test::Future' }
  sub transport_capabilities { qw(listen) }
  sub _listen_open        { DBIO::Test::Future->fail($_[0]{open_error}) }
  sub _listen_close       { return }
  sub _listen_subscribe   { DBIO::Test::Future->fail($_[0]{sub_error}) }
  sub _listen_unsubscribe { DBIO::Test::Future->done }
  sub _listen_watch       { return }
  sub _listen_unwatch     { return }
  sub _listen_probe       { 1 }
  sub _listen_delay       { DBIO::Test::Future->new }
}

sub transport {
  my (%conninfo) = @_;
  my $s = K392::Transport->new(undef);
  $s->connect_info([ { %conninfo }, {} ]);
  $s->{errors} = [];
  $s->on_listen_error(sub { push @{ $_[0]{errors} }, $_[1] });
  return $s;
}

subtest 'the open of the listen connection' => sub {
  my $s = transport(dsn => 'dbi:Pg:dbname=app;host=db', user => 'bob', password => 'hunter2-secret');
  $s->{open_error} = 'FATAL: password authentication failed (hunter2-secret) for "bob"; '
                   . 'conninfo dbname=app password=other-secret';
  my $f = $s->listen(chan => sub {});

  is scalar @{ $s->{errors} }, 1, 'the failure is reported once';
  like $s->{errors}[0], qr/^opening the listen connection failed: /, 'with its context';
  unlike $s->{errors}[0], qr/hunter2-secret|other-secret/, 'the hook never sees a password';
  ok $f->is_failed, 'listen fails';
};

subtest 'LISTEN refused' => sub {
  my $s = transport(dsn => 'dbi:Pg:dbname=app', user => 'bob', password => 'hunter2-secret');
  $s->{open_error} = undef;
  no warnings 'redefine';
  local *K392::Transport::_listen_open = sub { DBIO::Test::Future->done(bless {}, 'K392::Conn') };
  $s->{sub_error} = 'permission denied for hunter2-secret; password=third-secret';
  my $f = $s->listen(chan => sub {});

  ok $f->is_failed, 'listen fails';
  my $msg = eval { $f->get; 1 } ? '' : "$@";
  like $msg, qr/LISTEN on channel 'chan' failed: permission denied/, 'the reason stays';
  unlike $msg, qr/hunter2-secret|third-secret/, 'the Future carries no password';
  unlike join("\n", @{ $s->{errors} }), qr/hunter2-secret|third-secret/, 'nor does the hook';
};

done_testing;
