use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Run;
use App::plasm;

is(
  Run->run('--version'),
  object {
    call out => match qr/^plasm version (dev|[0-9]+\.[0-9]{2}) Wasm.pm [0-9]+\.[0-9]{2}$/;
    call err => '';
    call ret => 0;
  },
  '% plasm --version'
);

is(
  Run->run('--help'),
  object {
    call out => match qr/Usage:/;
    call err => '';
    call ret => 0;
  },
  '% plasm --help',
);

is(
  Run->run('bogus'),
  object {
    call out => '';
    call err => match qr/no subcommand 'bogus'/;
    call ret => 2;
  },
  '% plasm bogus'
);

is(
  Run->run('--bogus'),
  object {
    call out => '';
    call err => match qr/Unknown option: bogus/;
    call ret => 2;
  },
  '% plasm --bogus'
);

is(
  Run->run,
  object {
    call out => '';
    call err => match qr/Usage:/;
    call ret => 2;
  },
  '% plasm --bogus'
);

done_testing;


