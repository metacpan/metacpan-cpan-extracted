use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Run;

unlink 'corpus/empty.wasm';

is(
  Run->run('wat', 'corpus/empty.wat'),
  object {
    call out => '';
    call err => '';
    call ret => 0;
  },
  '% plasm wat corpus/empty.wat',
);

ok -f 'corpus/empty.wasm';

unlink 'corpus/empty.wasm';


done_testing;
