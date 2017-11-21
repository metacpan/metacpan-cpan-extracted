use Test2::Bundle::Extended;
use POSIX qw();
use Argon::Test;
use Argon::Constants qw(:commands);
use Argon::Message;
use Argon::Channel;
use Argon::Log;

my @MSGS = map { Argon::Message->new(cmd => $QUEUE, info => $_) } 1 .. 4;

ar_test 'positive path', 10, sub {
  my $cv = shift;
  my (@msgs1, $error1);
  my (@msgs2, $error2);

  my ($ch1, $ch2) = channel_pair(
    {
      on_msg => sub { push @msgs1, $_[1] },
      on_err => sub { $error1 = $_[1] },
    },
    {
      on_msg => sub { push @msgs2, $_[1]; $cv->end; },
      on_err => sub { $error2 = $_[1] },
    },
  );

  ok $ch1, 'new';
  ok $ch2, 'new';

  foreach (@MSGS) {
    $ch1->send($_);
    $cv->begin;
  }

  $cv->recv;

  is @msgs2, @MSGS, 'send/recv';
  ok !$error1, 'left channel: no error';
  ok !$error2, 'right channel: no error';
};

done_testing;
