use Test::More;

use strictures 2;

use Bot::Cobalt::Plugin::Calc::Session;

use POE;

my $expr  = '2 * 2';
my $hints = +{ foo => 'bar' };

my $res;

alarm 30;

my $calc = Bot::Cobalt::Plugin::Calc::Session->new;

POE::Session->create(
  inline_states => +{
    _start => sub {
      $poe_kernel->sig(ALRM => 'timeout');
      $calc->start;
      diag "Posting '$expr'";
      $poe_kernel->post( $calc->session_id, calc => $expr, $hints );
      $_[HEAP]->{calc} = $calc;
    },
    timeout => sub { die "Timed out!" },
    calc_result => sub {
      diag "Got result";
      $res = $_[ARG0];
      is $res, '4', '2 * 2 = 4';
      is_deeply $_[ARG1], $hints, 'hints hash matches';
      $poe_kernel->post( $_[HEAP]->{calc}->session_id, 'shutdown' );
    },
    calc_error => sub {
      my $err = $_[ARG0];
      fail "Received unexpected calc_error: '$err'";
      $poe_kernel->post( $_[HEAP]->{calc}->session_id, 'shutdown' );
    },
  },
);

POE::Kernel->run;

is $res, '4', 'got expected result';
ok !%{ $calc->_wheels }, 'WHEELS cleaned up';
ok !%{ $calc->_tag_by_wid }, 'TAG_BY_WID cleaned up';
ok !%{ $calc->_requests }, 'REQUESTS cleaned up';

done_testing
