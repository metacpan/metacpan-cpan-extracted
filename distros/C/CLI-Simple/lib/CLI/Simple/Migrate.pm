package CLI::Simple::Migrate;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Helpers qw(:all);
use CLI::Simple::Scaffold qw(_cmd_scaffold);

use English qw(-no_match_vars);

use parent qw(Exporter);
our @EXPORT_OK = qw(_cmd_migrate);

########################################################################
sub _cmd_migrate {
########################################################################
  my ( $class, $commands, $option_specs ) = @_;

  # dump spec with role class names then scaffold
  my $yaml      = _generate_spec_yaml( $class, $commands, $option_specs, $TRUE );
  my $spec_file = _spec_filename($class);

  open my $fh, '>', $spec_file
    or die "ERROR: could not write $spec_file: $OS_ERROR\n";
  print {$fh} $yaml;
  close $fh;

  printf {*STDOUT} "wrote %s\n", $spec_file;

  # now scaffold from the spec we just wrote
  _cmd_scaffold( $class, $commands, $option_specs );

  return $SUCCESS;
}

1;
