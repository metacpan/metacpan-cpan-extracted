#!/usr/bin/env perl
use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;

subtest 'lone dash on leaf node' => sub {
   test_run({ execute => sub { } }, [qw< foo >], {}, undef)
     ->no_exceptions->stderr_like(qr{\A\s*\z},
      'no complaints on standard error');
};

subtest 'lone dash on an intermediate node' => sub {
   # this is how it's done properly when there are children... have to
   # set a fallback_to -self to avoid die-ing because the child is not
   # found.
   test_run(
      {
         execute => sub { },
         fallback_to => '-self',
         force_auto_children => 1,
      }, [qw< foo >], {}, undef)
     ->no_exceptions->stderr_like(qr{\A\s*\z},
      'no complaints on standard error');
};

done_testing();
