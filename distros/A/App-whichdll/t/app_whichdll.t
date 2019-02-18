use Test2::V0 -no_srand => 1;
use App::whichdll;
use Test::Script 1.09;

subtest 'version' => sub {

  script_runs(
    [ 'bin/whichdll', '-v' ],
    { exit => 2 },
    'script runs',
  );

  script_stdout_like qr{whichdll running FFI::CheckLib};
  
};

done_testing;
