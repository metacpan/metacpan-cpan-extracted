use strict;
use warnings;

use Test::More;
use CLI::Simple;

{
  package Local::OptionConstructor;
  use parent qw(CLI::Simple);
  sub cmd_run { return 0; }
}

subtest 'metadata declarations retain ordinary Getopt parsing' => sub {
  local @ARGV = ( '--port', '9090', 'run' );
  my $app = Local::OptionConstructor->new(
    options => { 'port|p=i' => { description => 'Port', min => 1 } },
    commands => { run => \&Local::OptionConstructor::cmd_run },
  );
  is( $app->get_port, 9090, 'parsed value available' );
  is( $app->{_cli_simple_option_metadata}{port}{description}, 'Port', 'metadata retained' );
};

subtest 'legacy option_specs remains valid' => sub {
  local @ARGV = ( '--port', '8080', 'run' );
  my $app = Local::OptionConstructor->new(
    option_specs => [ 'port|p=i' ],
    commands     => { run => \&Local::OptionConstructor::cmd_run },
  );
  is( $app->get_port, 8080, 'legacy parsing works' );
};

subtest 'ambiguous constructor declarations rejected' => sub {
  local @ARGV = ('run');
  my $ok = eval {
    Local::OptionConstructor->new(
      options      => { 'port=i' => {} },
      option_specs => [ 'port=i' ],
      commands     => { run => \&Local::OptionConstructor::cmd_run },
    );
    1;
  };
  ok( !$ok, 'both forms rejected' );
  like( $@, qr/options and option_specs cannot both be supplied/, 'clear error' );
};

done_testing;
1;
