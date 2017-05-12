
use strict;
use warnings;
use Module::Build;
use File::Spec;

# Automatically create Telescope/MPC.pm.
my $class = Module::Build->subclass(
                                    class => "Module::Build::CustomAstroTelescope",
                                    code => join( "", <DATA> ),
                                   );

my $file = File::Spec->catfile( "lib", "Astro", "Telescope.pm" );

# Now configure it further
my $build = $class->new
  (
   module_name => 'Astro::Telescope',
   license  => 'perl',
   abstract_from => $file,
   version_from => $file,
   dist_author => [
                   'Tim Jenness <tjenness@cpan.org>',
                   'Brad Cavanagh <bradc@cpan.org>',
                  ],
   meta_merge => {
                  resources =>  {
                                 repository => "git://github.com/timj/perl-Astro-Telescope.git",
                                 homepage => "http://github.com/timj/perl-Astro-Telescope/tree/master",
                                },
                 },
   configure_requires => {
                          "Module::Build" => 0.30,
                         },
   requires => {
                'Astro::PAL' => 0.99,
               },
   build_requires => {
                      'Test::More' => 0,
                     },
  );

$build->create_build_script;

# This is the subclass code to handle dynamic generation of the git version
# status when running Build
# Always generate this file. The overhead is small and we want to make sure that
# it is correct whenever the module is built. No reason to use something cleverer.
__DATA__

use File::Spec;
use warnings;
use strict;

sub ACTION_build {

  my $self = shift;

  print "Generating MPC lookup table support module Astro::Telescope::MPC...\n";

  # Locations of input and output files
  my $mpc_data = File::Spec->catfile("tmpl", "MPC.dat");
  my $mpc_dir = File::Spec->catdir("lib", "Astro", "Telescope");
  my $mpc_pm   = File::Spec->catfile($mpc_dir, "MPC.pm");

  # Create output directory
  if ( !-d $mpc_dir) {
    mkdir $mpc_dir
      or die "Error creating MPC module. Unable to make directory $mpc_dir: $!";
  }

  # Open the input and output handles
  open(my $MPC_DATA_FH, $mpc_data) ||
    die "Unable to open MPC stub file $mpc_data : $!\n";
  open(my $MPC_PM_FH, ">", "$mpc_pm") ||
    die "Unable to open MPC stub file $mpc_pm : $!\n";

  # Write out the module code
  print $MPC_PM_FH q|

# This file has been generated automatically by the
# Astro::Telescope build system. Do not edit directly.
# Edit Build.PL or tmpl/MPC.dat instead.

package Astro::Telescope::MPC;

use strict;
use warnings;
use vars qw/ %obs_codes /;

use constant DD2R => 0.017453292519943295769236907684886127134428718885417;

sub parse_table {
  my $self = shift;
  return if %obs_codes;

  for (<DATA>) {
    my($code, $long, $par_S, $par_C, $mpcname) = unpack("A3A10A8A9A*", $_);
    next unless $long =~ /\d/; # Space telescope
    $obs_codes{$code} = { Long => ($long * DD2R),
                          Par_S => $par_S,
                          Par_C => $par_C,
                          Name => $mpcname,
                        };
  }

}

1;
__DATA__
|;

  while(<$MPC_DATA_FH>) {
    print $MPC_PM_FH $_;
  }
  close $MPC_DATA_FH || die "Error closing data input file: $!";
  close $MPC_PM_FH   || die "Error closing output module: $!";

  $self->SUPER::ACTION_build;
}

# Remove the file on clean
sub ACTION_clean {
  my $self = shift;
  # Ignore errors
  unlink File::Spec->catfile( "lib", "Astro", "Telescope", "MPC.pm" );
  $self->SUPER::ACTION_clean;
}

