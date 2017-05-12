
use strict;
use warnings;

use Benchmark qw( :all :hireswallclock );

my (@slaves);

# Spin up CPU Heaters.
for ( 0 .. 3 ) {
  my $pid = fork;
  if ($pid) {
    push @slaves, $pid;
    next;
  }
  while (1) {
    my $pos = rand() / rand();
  }
}

END {
  for my $slave (@slaves) {
    kill 'HUP', $slave;
  }
}

cmpthese(
  10_800_000,
  {
    'a' => sub {
      my $pos = 1 + rand(255);
      1;
    },
    'b' => sub {
      my $pos = 1 + rand(255) + rand(255);
      1;
    },
  }
);

for my $slave (@slaves) {
  kill 'HUP', $slave;
}
if ( $ENV{RUN_TWO} ) {
  cmpthese(
    700_000,
    {
      'a' => sub {
        my $pos = 1 + rand(255);
        1;
      },
      'b' => sub {
        my $pos = 1 + rand(255) + rand(255);
        1;
      },
    }
  );
}
