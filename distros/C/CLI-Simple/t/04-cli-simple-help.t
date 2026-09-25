#!/usr/bin/env perl

# Test::Exit must be compiled before other code that calls exit
use English qw(-no_match_vars);
use Test::Exit;
use Test::More;

use lib 't/lib';

use CLISimpleHelpBoth;
use CLISimpleHelpSynopsis;
use CLISimpleHelpUsage;

BEGIN {
  use_ok( qw(CLI::Simple), qw($AUTO_HELP $PAGER) );
}

$PAGER = 0;

########################################################################
sub capture_usage {
########################################################################
  my ( $cli, $module ) = @_;

  my $output = q{};

  open my $stdout, '>', \$output
    or die "Could not open scalar filehandle: $OS_ERROR";

  $cli->set__program( $INC{$module} );

  {
    local *STDOUT = $stdout;

    exits_ok {
      $cli->usage();
    }
    'usage exits';
  }

  close $stdout
    or die "Could not close scalar filehandle: $OS_ERROR";

  return $output;
}

########################################################################
subtest 'USAGE is legacy fallback' => sub {
########################################################################
  local @ARGV;

  my $cli = CLISimpleHelpUsage->new(
    commands     => { foo => \&CLISimpleHelpUsage::cmd_foo },
    option_specs => [],
  );

  my $output = capture_usage( $cli, 'CLISimpleHelpUsage.pm' );

  like( $output, qr/LEGACY USAGE TEXT/sm, 'USAGE content displayed when SYNOPSIS is absent', );

  return;
};

########################################################################
subtest 'SYNOPSIS is used for default help' => sub {
########################################################################
  local @ARGV;

  my $cli = CLISimpleHelpSynopsis->new(
    commands     => { foo => \&CLISimpleHelpSynopsis::cmd_foo },
    option_specs => [],
  );

  my $output = capture_usage( $cli, 'CLISimpleHelpSynopsis.pm' );

  like( $output, qr/SYNOPSIS TEXT/sm, 'SYNOPSIS content displayed', );

  return;
};

########################################################################
subtest 'SYNOPSIS takes precedence over USAGE' => sub {
########################################################################
  local @ARGV;

  my $cli = CLISimpleHelpBoth->new(
    commands     => { foo => \&CLISimpleHelpBoth::cmd_foo },
    option_specs => [],
  );

  my $output = capture_usage( $cli, 'CLISimpleHelpBoth.pm' );

  like( $output, qr/SYNOPSIS TEXT/sm, 'SYNOPSIS content displayed', );

  unlike( $output, qr/LEGACY USAGE TEXT/sm, 'USAGE content suppressed', );

  return;
};

########################################################################
subtest 'explicit help_sections are honored' => sub {
########################################################################
  local @ARGV;

  my $cli = CLISimpleHelpBoth->new(
    commands     => { foo => \&CLISimpleHelpBoth::cmd_foo },
    option_specs => [],
  );

  $cli->set_help_sections( [qw(SYNOPSIS USAGE)] );

  my $output = capture_usage( $cli, 'CLISimpleHelpBoth.pm' );

  like( $output, qr/SYNOPSIS TEXT/sm, 'SYNOPSIS content displayed', );

  like( $output, qr/LEGACY USAGE TEXT/sm, 'explicit USAGE content displayed', );

  return;
};

done_testing;

1;
