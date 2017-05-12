use 5.008000;
use strict;
use warnings;

use Test::More tests => 12;
use Config::Processor;

my $CONFIG_PROCESSOR = Config::Processor->new();

can_ok( $CONFIG_PROCESSOR, 'interpolate_variables' );
can_ok( $CONFIG_PROCESSOR, 'process_directives' );
can_ok( $CONFIG_PROCESSOR, 'export_env' );

t_interpolate_variables($CONFIG_PROCESSOR);
t_process_directives($CONFIG_PROCESSOR);
t_export_env($CONFIG_PROCESSOR);


sub t_interpolate_variables {
  my $config_processor = shift;

  my $interpolate_variables = $config_processor->interpolate_variables;
  is( $interpolate_variables, 1, 'get variable interpolation switch value' );

  $config_processor->interpolate_variables(undef);
  is( $config_processor->interpolate_variables,
      undef, 'disable variable interpolation' );

  $config_processor->interpolate_variables(1);
  is( $config_processor->interpolate_variables, 1,
      "enable variable interpolation" );

  return;
}

sub t_process_directives {
  my $config_processor = shift;

  my $process_directives = $config_processor->process_directives;
  is( $process_directives, 1, 'get directive processing switch value' );

  $config_processor->process_directives(undef);
  is( $config_processor->process_directives,
      undef, 'disable directive processing' );

  $config_processor->process_directives(1);
  is( $config_processor->process_directives, 1, "enable directive processing" );

  return;
}

sub t_export_env {
  my $config_processor = shift;

  my $export_env = $config_processor->export_env;
  is( $export_env, undef, 'get ENV exporting switch value' );

  $config_processor->export_env(1);
  is( $config_processor->export_env, 1, 'enable ENV exporting' );

  $config_processor->export_env(undef);
  is( $config_processor->export_env, undef, "disable directive processing" );

  return;
}
