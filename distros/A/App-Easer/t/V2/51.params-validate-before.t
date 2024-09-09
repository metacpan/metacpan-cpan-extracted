use v5.24;
use experimental 'signatures';
use Test::More;


eval 'use Params::Validate';
plan skip_all => 'Params::Validate required for this test' if $@;

use File::Basename 'dirname';
use lib dirname(__FILE__);

# get this stuff at runtime
require LocalTester;
LocalTester->import;

my $file_prefix = __FILE__ =~ s{\.t\z}{}rmxs;

my $app = {
   aliases     => ['MAIN'],
   help        => 'example command',
   description => 'An example command',
   options     => [
      {
         getopt      => 'foo|f=s',
         environment => 'GALOOK_FOO',
      },
      {
         getopt      => 'bar|b=s',
         environment => 'GALOOK_BAR',
         default     => 'buzz',
      },
   ],
   params_validate => {
      config => { foo => 1, bar => { regex => qr{(?imxs:\A b)} } },
      args   => [1, 0],
   },
   execute => sub ($self) { print {*STDOUT} 'FOO'; return 42 },
};

subtest '--foo hello all' => sub {
   test_run($app, [qw< --foo hello all >], {}, 'baz')
     ->no_exceptions->result_is(42)->stdout_like(qr{FOO});
};

subtest '--foo hello all folks' => sub {
   test_run($app, [qw< --foo hello all folks >], {}, 'baz')
     ->no_exceptions->result_is(42)->stdout_like(qr{FOO});
};

subtest 'all' => sub {
   test_run($app, [qw< all >], {}, 'baz')
     ->exception_like(qr{(?mxs:Mandatory \s+ parameter \s+ 'foo')},
        'missing required option --foo');
};

subtest '--foo hello' => sub {
   test_run($app, [qw< --foo hello >], {}, 'baz')
     ->exception_like(qr{(?mxs:0 \s+ parameters.*but \s 1)},
        'missing required positional arg');
};

subtest '--foo hello all of you' => sub {
   test_run($app, [qw< --foo hello all of you >], {}, 'baz')
     ->exception_like(qr{(?mxs:3 \s+ parameters.*but \s 1)},
        'too many positional args');
};


done_testing();

1;
