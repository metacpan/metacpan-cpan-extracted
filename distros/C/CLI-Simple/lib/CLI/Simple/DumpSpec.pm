package CLI::Simple::DumpSpec;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Helpers qw(:all);
use English qw(-no_match_vars);

use parent qw(Exporter);

our @EXPORT_OK = qw(_cmd_dump_spec);

########################################################################
sub _cmd_dump_spec {
########################################################################
  my ( $class, $commands, $option_specs ) = @_;

  my $use_roles = ( $ARGV[1] // q{} ) eq 'roles';

  my $spec_file = _spec_filename($class);
  my $yaml      = _generate_spec_yaml( $class, $commands, $option_specs, $use_roles );

  open my $fh, '>', $spec_file
    or die "ERROR: could not write $spec_file: $OS_ERROR\n";

  print {$fh} $yaml;

  close $fh
    or warn "WARNING: could not close $spec_file: $OS_ERROR\n";

  printf {*STDOUT} "wrote %s\n", $spec_file;
  printf {*STDOUT} "your main() can now be replaced with:\n\n";
  printf {*STDOUT} "  caller or exit __PACKAGE__->main;\n\n";
  printf {*STDOUT} "see: perldoc CLI::Simple\n";

  return $SUCCESS;
}

1;

__END__
