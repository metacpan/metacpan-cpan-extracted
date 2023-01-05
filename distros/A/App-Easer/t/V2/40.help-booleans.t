use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;

my $file_prefix = __FILE__ =~ s{\.t\z}{}rmxs;

my $app = {
   aliases             => ['MAIN'],
   help                => 'example command',
   description         => 'An example command',
   options             => [
      {getopt => 'foo|f!'},
      {getopt => 'bar|b'},
      {getopt => 'opta=s@'},
      {getopt => 'optb:s'},
      {getopt => 'optc+'},
      {getopt => 'optd:+'},
      {getopt => 'opte:4'},
   ],
   force_auto_children => 1,    # get "help" and "commands" sub-commands
};

subtest 'help' => sub {
   test_run($app, ['help'], {}, undef)
     ->no_exceptions
     #->diag_stdout
     ->stdout_like(
      qr{(?mxs:^\s* --foo \s*\| \s* --no-foo \s*$)},
      'boolean option with negation')
     ->stdout_like(qr{(?mxs:^\s* --bar \s*$)},
      'boolean option without negation');
};

done_testing();
