use Test2::Bundle::Extended;
use Argon::Task;
use Argon;

ok my $task = Argon::Task->new('sub { use List::Util qw(sum); sum(@_) }', [1, 2, 3]), 'new';

do {
  local $Argon::ALLOW_EVAL = 1;
  is $task->run, 6, 'expected result';
};

do {
  local $Argon::ALLOW_EVAL = 0;
  ok dies { $task->run }, 'dies when ALLOW_EVAL is false';
};

done_testing;
