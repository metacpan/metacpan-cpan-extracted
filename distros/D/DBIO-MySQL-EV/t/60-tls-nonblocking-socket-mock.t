use strict;
use warnings;
use Test::More;
use Fcntl ();
use Socket ();

BEGIN {
  eval { require EV::MariaDB; 1 } or plan skip_all => 'EV::MariaDB not installed';
}
use DBIO::MySQL::EV::Pool;

alarm 30;

# OFFLINE, karr k85, k95. Over TLS libmariadb leaves the socket blocking and holds
# the event loop for every statement. The handle seam, where every EV::MariaDB
# handle of the dist is made, sets O_NONBLOCK on the handle's socket in its
# on_connect (so again after every reconnect) and runs the caller's on_connect
# after that -- for EVERY handle, whatever the connect info holds (k95: k85 did it
# only for a ssl_* parameter; measured live on MySQL 8.0 and MariaDB 11.8, the
# flag changes nothing over plain TCP, and the connect info does not tell whether
# TLS was negotiated). The live proof that the loop then runs is
# t/52-tls-concurrent-live.t; this file pins the decision and the wiring against
# a fake handle with a real socket.

sub flags { my $fd = shift; open(my $d, '+<&', $fd) or die $!; my $f = fcntl($d, Fcntl::F_GETFL(), 0); close $d; return $f }
sub nonblocking { return (flags(shift) & Fcntl::O_NONBLOCK()) ? 1 : 0 }

socketpair(my $a, my $b, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0) or die $!;
my $fd = fileno $a;

{
  package FakeMdb;
  sub socket { $_[0]{fd} }
}

my @made;
no warnings qw( redefine once );
local *EV::MariaDB::new = sub { shift; my $m = bless { fd => $fd }, 'FakeMdb'; push @made, [ $m, { @_ } ]; return $m };

sub make {
  my (%args) = @_;
  @made = ();
  my $mdb = DBIO::MySQL::EV::Pool->_mysql_new_handle(host => 'h', user => 'u', %args);
  return ($mdb, $made[0][1]);
}

ok !nonblocking($fd), 'the test socket starts blocking';

for my $param (qw( ssl_key ssl_cert ssl_ca ssl_capath ssl_cipher )) {
  my $called = 0;
  my ($mdb, $seen) = make($param => 'x', on_connect => sub { $called++; return });
  ok !nonblocking($fd), "$param: nothing is touched before the connect completes";
  $seen->{on_connect}->();
  ok nonblocking($fd), "$param: the socket is non-blocking once on_connect fired";
  is $called, 1, "$param: the caller's on_connect still ran";

  # a reconnect: blocking again (the client library made a new socket), fired again
  my $fl = flags($fd);
  fcntl(do { open(my $d, '+<&', $fd); $d }, Fcntl::F_SETFL(), $fl & ~Fcntl::O_NONBLOCK());
  ok !nonblocking($fd), "$param: (the socket is made blocking again, as a reconnect would)";
  $seen->{on_connect}->();
  ok nonblocking($fd), "$param: again non-blocking after the second on_connect";
  is $called, 2, "$param: ... and the caller's on_connect ran again";
  fcntl(do { open(my $d, '+<&', $fd); $d }, Fcntl::F_SETFL(), flags($fd) & ~Fcntl::O_NONBLOCK());
}

{
  # k95: this replaces the k85 claim "plain TCP (no ssl_* parameter): the socket is
  # left as the client library made it".
  my $called = 0;
  my ($mdb, $seen) = make(on_connect => sub { $called++; return });
  ok !nonblocking($fd), 'no ssl_* parameter: nothing is touched before the connect completes';
  $seen->{on_connect}->();
  ok nonblocking($fd), 'no ssl_* parameter: the socket is non-blocking too once on_connect fired (k95)';
  is $called, 1, '... and the caller\'s on_connect is called';
  fcntl(do { open(my $d, '+<&', $fd); $d }, Fcntl::F_SETFL(), flags($fd) & ~Fcntl::O_NONBLOCK());
}

{
  my ($mdb, $seen) = make();
  ok ref $seen->{on_connect} eq 'CODE', 'no ssl_* parameter and no caller on_connect: the seam still sets one';
  ok eval { $seen->{on_connect}->(); 1 }, '... that runs fine';
  ok nonblocking($fd), '... and sets the flag';
  fcntl(do { open(my $d, '+<&', $fd); $d }, Fcntl::F_SETFL(), flags($fd) & ~Fcntl::O_NONBLOCK());
}

{
  my ($mdb, $seen) = make(ssl_cipher => 'DEFAULT');
  ok ref $seen->{on_connect} eq 'CODE', 'TLS without a caller on_connect: the seam still sets one';
  ok eval { $seen->{on_connect}->(); 1 }, '... that runs fine';
  ok nonblocking($fd), '... and sets the flag';
  fcntl(do { open(my $d, '+<&', $fd); $d }, Fcntl::F_SETFL(), flags($fd) & ~Fcntl::O_NONBLOCK());
}

{
  my ($mdb, $seen) = make(on_connect => sub { 1 });
  ok !exists $seen->{ssl_cipher}, 'no ssl_* parameter: none is added to the handle\'s arguments';
}

{
  # a handle gone before its on_connect fires, and a handle with no socket: no die
  my ($mdb, $seen) = make(ssl_cipher => 'DEFAULT');
  $mdb->{fd} = -1;
  ok eval { $seen->{on_connect}->(); 1 }, 'a handle without a socket: on_connect does not die';
  undef $mdb;
  ok eval { $seen->{on_connect}->(); 1 }, 'a dropped handle: on_connect does not die';
}

is(DBIO::MySQL::EV::Pool::_mysql_socket_nonblocking(bless { fd => -1 }, 'FakeMdb'), 0,
  '_mysql_socket_nonblocking: no socket, false');

done_testing;
