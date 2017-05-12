#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{DEVICE_CURRENT_COST_TEST_DEBUG}
};
use Test::More;
use Test::Requires qw/Test::SharedFork Test::Warn/;
use Test::SharedFork;
use Test::Warn;
use IO::Pipe;
use AnyEvent;
$ENV{PERL_ANYEVENT_MODEL} = 'Perl' unless ($ENV{PERL_ANYEVENT_MODEL});

plan tests => 4;

$|=1;
use_ok('AnyEvent::CurrentCost');

my $pipe = IO::Pipe->new;
my $pid = fork();
if ($pid == 0) {
  # child
  $pipe->writer;
  $pipe->autoflush;
  print $pipe q{<msg><src>CC128-v0.11</src><dsb>00596</dsb><time>17:02:42</time><tmpr>27.2</tmpr><sensor>0</sensor><id>00077</id><type>1</type><ch1><watts>01380</watts></ch1></msg><msg><src>truncated};

  select undef, undef, undef, 1.5;

  print $pipe q{<msg><src>CC128-v0.11</src><dsb>00596</dsb><time>17:02:42</time><tmpr>27.2</tmpr><sensor>0</sensor><id>00077</id><type>1</type><ch1><watts>01999</watts></ch1></msg>};

  close $pipe;

} elsif ($pid) {
  # parent
  $pipe->reader;
  my $cv = AnyEvent->condvar;
  my $dev = AnyEvent::CurrentCost->new(filehandle => $pipe,
                                       discard_timeout => 0.5,
                                       callback => sub { $cv->send($_[0]) });
  my $msg = $cv->recv;
  is($msg->value, 1380, 'first value');
  $cv = AnyEvent->condvar;
  AnyEvent->timer(after => 1.5, sub { $cv->send });
  warning_like { $msg = $cv->recv }
    {carped => qr/Discarding '<msg><src>truncated'/}, 'discard timeout';
  is($msg->value, 1999, 'second value');

  waitpid $pid, 0;
} else {
  die $!;
}

sub test_error {
  eval { shift->() };
  local $_ = $@;
  s/\s+at\s.*$//s;
  $_;
}
