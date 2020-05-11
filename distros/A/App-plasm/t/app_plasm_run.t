use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Run;

is(
  # Note: after running this test the command-line arguments
  # have been set, we can't test command-line arguments again
  # in this process.
  Run->run('run', 'corpus/echo.wasm', 'one', 'two','three'),
  object {
    call out => "0:corpus/echo.wasm\n" .
                "1:one\n" .
                "2:two\n" .
                "3:three\n";
    call err => '';
    call ret => 0;
  },
  '% plasm run corpus/hello.wasm',
);

is(
  Run->run('run', 'corpus/hello.wasm'),
  object {
    call out => "hello world!\n";
    call err => '';
    call ret => 0;
  },
  '% plasm run corpus/hello.wasm',
);

is(
  Run->run('run', '--help'),
  object {
    call out => match qr/plasm run program\.wasm \[ arguments \]/;
    call err => '';
    call ret => 0;
  },
  '% plasm run --help',
);

is(
  Run->run('run', '--bogus'),
  object {
    call out => '';
    call err => match qr/Unknown option: bogus/;
    call ret => 2;
  },
  '% plasm run --bogus',
);

is(
  Run->run,
  object {
    call out => '';
    call err => match qr/Usage:/;
    call ret => 2;
  },
  '% plasm run',
);

is(
  Run->run('run', 'corpus/bogus.wasm'),
  object {
    call out => '';
    call err => match qr/File not found: corpus\/bogus\.wasm/;
    call ret => 2;
  },
  '% plasm run corpus/bogus.wasm',
);

done_testing;
