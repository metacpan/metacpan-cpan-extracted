use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;

subtest 'help me to help' => sub {
   test_run({force_auto_children => 1}, [qw< help help >], {}, undef)
     ->no_exceptions->stdout_like(qr{Print help for \(sub\)command},
      q{help's help text})
     ->stderr_like(qr{\A\s*\z}, 'no complaints on standard error');
   test_run({force_auto_children => 1}, [qw< help commands >], {}, undef)
     ->no_exceptions->stdout_like(qr{Print list of supported sub-command},
      q{command's help text})
     ->stderr_like(qr{\A\s*\z}, 'no complaints on standard error');
   test_run({force_auto_children => 1}, [qw< help tree >], {}, undef)
     ->no_exceptions->stdout_like(qr{Print tree of supported sub-command},
      q{tree's help text})
     ->stderr_like(qr{\A\s*\z}, 'no complaints on standard error');
};

done_testing();
