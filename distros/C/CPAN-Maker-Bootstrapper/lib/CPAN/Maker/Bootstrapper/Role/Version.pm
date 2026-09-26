package CPAN::Maker::Bootstrapper::Role::Version;

use strict;
use warnings;

# use CPAN::Maker::Bootstrapper qw($VERSION);

use CLI::Simple::Constants qw(:booleans);
use CPAN::Maker::Bootstrapper::Constants qw(:all);
use Cwd qw(abs_path getcwd);
use Data::Dumper;
use English qw(-no_match_vars);
use File::ShareDir qw(dist_dir);

use Role::Tiny;

########################################################################
sub cmd_version {
########################################################################
  my ($self) = @_;

  print {*STDERR} sprintf "CPAN::Maker::Bootstrapper v%s\n", '2.3.3';
  print {*STDERR} sprintf "Copyright 2026 (c) Robert C. Lauer, All rights reserved.\n";

  return $SUCCESS;
}

1;

__END__
