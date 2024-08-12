use strict;
use warnings;

package App::Prove::Plugin::TestArgs;

use Class::Method::Modifiers qw( install_modifier );
use String::Format           qw( stringf );
use YAML::PP                 qw( LoadFile );

# keeping the following $VERSION declaration on a single line is important
#<<<
use version 0.9915; our $VERSION = version->declare( '2.1.1' );
#>>>

my $command_line_test_args;
# script means test script
my %script_has_alias;

sub load {
  my $plugin_name = shift;
  my ( $app_prove, $plugin_args ) = @{ +shift }{ qw( app_prove args ) };

  $command_line_test_args = defined $app_prove->test_args ? $app_prove->test_args : [];
  # initialize (overwrite) test args
  $app_prove->test_args( {} );

  my $config = LoadFile( $plugin_args->[ 0 ] );

  my $scripts = exists $config->{ scripts } ? $config->{ scripts } : $config;
  for my $script ( keys %$scripts ) {
    for ( @{ $scripts->{ $script } } ) {
      my ( $alias, $script_args ) = @{ $_ }{ qw( alias args ) };
      $alias = stringf( $config->{ name }, { a => $alias, s => $script } ) if exists $config->{ name };
      # update test args ("args" is optional)
      $app_prove->test_args->{ $alias } = defined $script_args ? $script_args : $command_line_test_args;
      push @{ $script_has_alias{ $script } }, [ $script, $alias ];
    }
  }
}

install_modifier 'App::Prove', 'around', '_get_tests' => sub {
  my $_get_tests_orig = shift;
  my $app_prove       = shift;

  my @tests;
  for ( $app_prove->$_get_tests_orig( @_ ) ) {
    if ( exists $script_has_alias{ $_ } ) {
      push @tests, @{ $script_has_alias{ $_ } };
    } else {
      my $alias = $_;
      push @tests, [ $_, $alias ];
      # register remaining test scripts to avoid the excetion
      # TAP::Harness Can't find test_args for ... at ...
      $app_prove->test_args->{ $alias } = $command_line_test_args;
    }
  }
  undef $command_line_test_args;
  undef %script_has_alias;

  return @tests;
};

1;
