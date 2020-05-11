use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Run;

is(
  Run->run('dump', 'corpus/empty.wat'),
  object {
    call out => "(module)\n";
    call err => '';
    call ret => 0;
  },
  '% plasm dump corpus/empty.wat',
);

is(
  Run->run('dump', 'corpus/callback.wat'),
  object {
    call out => match qr/^\(module.*\)$/s;
    call err => '';
    call ret => 0;
  },
  '% plasm dump corpus/callback.wat',
);

done_testing;
