#<<<
use strict; use warnings;
#>>>

package App::Prove::Plugin::TestArgs;

use Class::Method::Modifiers qw( install_modifier );
use Config::Any              qw();

our $VERSION = '1.000000';

my $command_line_test_args;
my %test_script_has_alias;

sub load {
  my $plugin_name = shift;
  my ( $app_prove, $plugin_args ) = @{ +shift }{ qw( app_prove args ) };

  $command_line_test_args = defined $app_prove->test_args ? $app_prove->test_args : [];
  # initialize (overwrite) test args
  $app_prove->test_args( {} );

  my $config;
  {
    no warnings 'once'; ## no critic (ProhibitNoWarnings)
    local $YAML::Preserve = 1; ## no critic (ProhibitPackageVars)
    ( undef, $config ) =
      %{ Config::Any->load_files( { files => [ $plugin_args->[ 0 ] ], use_ext => 1, flatten_to_hash => 1 } ) };
  }

  for my $test_script ( keys %$config ) {
    for ( @{ $config->{ $test_script } } ) {
      my ( $alias, $test_script_args ) = @{ $_ }{ qw( alias args ) };
      # update test args ("args" is optional)
      $app_prove->test_args->{ $alias } = defined $test_script_args ? $test_script_args : $command_line_test_args;
      push @{ $test_script_has_alias{ $test_script } }, [ $test_script, $alias ];
    }
  }
}

install_modifier 'App::Prove', 'around', '_get_tests' => sub {
  my $_get_tests_orig = shift;
  my $app_prove       = shift;

  my @tests;
  for ( $app_prove->$_get_tests_orig( @_ ) ) {
    if ( exists $test_script_has_alias{ $_ } ) {
      push @tests, @{ $test_script_has_alias{ $_ } };
    } else {
      my $alias = $_;
      push @tests, [ $_, $alias ];
      # register remaining test scripts to avoid the excetion
      # TAP::Harness Can't find test_args for ... at ...
      $app_prove->test_args->{ $alias } = $command_line_test_args;
    }
  }
  undef $command_line_test_args;
  undef %test_script_has_alias;

  return @tests;
};

1;
