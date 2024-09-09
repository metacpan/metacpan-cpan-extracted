use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;

my $file_prefix = __FILE__ =~ s{\.t\z}{}rmxs;
my $json_config = "$file_prefix.json";

my $app = {
   aliases     => ['parent'],
   help        => 'example command',
   generate_auto_commands => 1,
   execute => sub ($self) {
      $self->run_help;
      return 42;
   },
};

my @options = (
   {
      getopt => 'foo=s',
      help => 'option without a default',
      stdout_unlike => qr{(?mxs:^\s+default:)},
   },
   {
      getopt => 'foo=s',
      help => 'single option with a default',
      default => 'bar-baz',
      stdout_like => qr{(?mxs:^\s+default:\s+bar-baz)},
   },
   {
      getopt => 'foo=s@',
      help => 'multiple-valued option with a default',
      default => [qw< bar baz >],
      stdout_like => qr{(?mxs:^\s+default:\s+\[\s*"bar"\s*,\s*"baz"\s*\])},
   },
);

for my $option (@options) {
   my ($lk, $unlk) = delete($option->@{qw< stdout_like stdout_unlike >});
   my $tester = delete($option->{_tester});
   $app->{options} = [ $option ];

   subtest $option->{help} => sub {
      my $t = test_run($app, [], {}, '')
         ->no_exceptions
         ->result_is(42);
      $t->stdout_like($lk) if $lk;
      $t->stdout_unlike($unlk) if $unlk;
   };
}

done_testing();
