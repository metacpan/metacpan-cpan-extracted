package CPAN::Maker::Bootstrapper::Role::ScaffoldImporter;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp choose);
use Cwd qw(abs_path);
use English qw(-no_match_vars);

use Role::Tiny;

########################################################################
sub cmd_import_scaffold {
########################################################################
  my ($self) = @_;

  my ($tarball) = $self->get_args;

  die "ERROR: tarball argument required\n"
    if !$tarball;

  die "ERROR: $tarball not found\n"
    if !-e $tarball;

  $tarball = abs_path($tarball);

  my $tmpdir = File::Temp::tempdir( CLEANUP => $TRUE );

  require Archive::Tar;

  chdir $tmpdir
    or die "ERROR: could not chdir to $tmpdir\n";

  Archive::Tar->extract_archive( $tarball, 1 )
    or die "ERROR: could not extract $tarball: " . Archive::Tar->error . "\n";

  $self->set_import( [$tmpdir] );

  return $self->cmd_install;
}

1;
