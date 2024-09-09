use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;

subtest 'run_help' => sub {
   my $t = test_run({execute => sub { shift->run_help }}, [], {}, undef)
     ->no_exceptions
     ->stdout_like(qr{no concise help yet}, 'default help text')
     ->stderr_like(qr{\A\s*\z}, 'no complaints on standard error');
};

subtest 'help' => sub {
   my $t = test_run({force_auto_children => 1}, ['help'], {}, undef)
     ->no_exceptions
     ->stdout_like(qr{no concise help yet}, 'default help text')
     ->stderr_like(qr{\A\s*\z}, 'no complaints on standard error');
};

done_testing();
