#!/opt/perl/bin/perl
use AnyEvent;
use AnyEvent::RetryTimer;

my $end = AE::cv;
my @intv;
my $retr_cnt = 0;
my $cur_ret;

my $tmr = AnyEvent::RetryTimer->new (
   on_retry =>sub {
      my ($tmr) = @_;

      $retr_cnt++;
      $cur_ret = AE::timer 0.1, 0, sub {
         $tmr->retry;
         push @intv, $tmr->current_interval;
      };
   },
   on_max_retries => sub {
      my ($tmr) = @_;
      $end->send;
   },
   max_retries    => 4,
   start_interval => 0.2,
   max_interval   => 0.4,
);

$tmr->retry;

print "1..2\n";

$end->recv;

my @intv_s = (0.2, 0.3, 0.4, 0.4);

my $match = (@intv_s == @intv);

for (@intv_s) {
   my $i = shift @intv;
   $match = 0
      unless ($i - 0.00001) < $_
          && ($i + 0.00001) > $_;
}

printf "%sok 1 - interval times as expected.\n",
       $match ? '' : 'not ';
printf "%sok 2 - 4 retries were done.\n",
       $retr_cnt == 5 ? '' : 'not ';
