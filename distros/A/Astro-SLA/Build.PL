
use strict;
use warnings;
use lib qw(inc);
use File::Spec;
use Module::Build;

# A makefile can be generated for either the C or Fortran version of
# SLALIB. It does not yet determine the C/Fortran-ness of your library
# automatically.

# Change this flag to control the behaviour of the build.
# This controls whether we are using the Fortran version (1),
# the C version (0) or the Starlink Fortran version (-1)
my $use_fortran = -1;

# Default location for the library. This is used if we fail to find
# starlink fortran (in which case it is assumed to be a C library)
# or use_fortran is set to 0 or 1

# Can be set externally with the SLA_ROOT environment variable
my $sla_root = "/usr/local/lib";

if (exists $ENV{SLA_ROOT} && defined $ENV{SLA_ROOT} && -d $ENV{SLA_ROOT}) {
  $sla_root = $ENV{SLA_ROOT};
}

my $sla_lib = "-L$sla_root/lib -lsla ";

# Same for include files [only relevant for C version] [use -I]
my $sla_inc = "-I$sla_root/include";

# Check valid range for the fortran switch
if ($use_fortran != 0 && $use_fortran != -1 && $use_fortran != 1) {
  print "use_fortran variable set to strange value. Assuming -1 [Starlink]\n";
}

# Starlink
if ($use_fortran == -1) {
  use vars qw/ %StarConfig /;

  # We first see if we can find Starlink::Config
  my $has_star_conf = eval "use Starlink::Config; 1;";

  if (!$has_star_conf) {
    # Look for Starlink via the environment else use /star
    my $root;
    for my $testdir ($ENV{STARLINK_DIR}, "/star", "/stardev") {
      if (defined $testdir && -d $testdir) {
        $root = $testdir;
        last;
      }
    }

    if (defined $root) {
      %StarConfig = (
                     Star_Inc => File::Spec->catdir($root, "include"),
                     Star_Lib => File::Spec->catdir($root,"lib"),
                     Star_Bin => File::Spec->catdir($root, "bin"),
                    );
    } else {
      print "Unable to locate Starlink system. Switching to C library.\n";
      $use_fortran = 0;
    }
  } else {
    print "Found Starlink configuration. Using $StarConfig{Star}\n";
  }

  # Work out the library full path
  my $lib = File::Spec->catfile($StarConfig{Star_Lib}, "libsla.a" );

  if (-e $lib) {
    print "Located Starlink SLALIB library in $StarConfig{Star_Lib}\n";

    # Sometimes we have to use CNF
    my $slalibs = qx/ sla_link /;
    $slalibs = "-lsla" unless defined $slalibs;

    $sla_lib = " -L$StarConfig{Star_Lib} $slalibs ";

    # Only do this hack for Linux
    $sla_lib .= "-Wl,-rpath,$StarConfig{Star_Lib} "
      if $^O eq 'linux';

    # See if we can find the version
    eval { require Starlink::Versions; };
    if (!$@) {
      my $ver = Starlink::Versions::starversion_string('sla');
      $ver = ( defined $ver ? $ver : "****** undefined ******" );
      print "It seems to be SLA version $ver\n";
    }

  } else {
    # Assume the C fallback
    $use_fortran = 0;
  }


}



# The #defines, libraries and any additional prerequisites
my (@defines, $libs, %build_prereqs);
if ($use_fortran) {
  print "Attempting to build against a Fortran SLALIB: $sla_lib\n";

  # Must switch modes
  push(@defines, "-DUSE_FORTRAN");

  # Must include fortran libraries but we do not want to force
  # ExtUtils::F77 on an unsuspecting C user
  $build_prereqs{'ExtUtils::F77'} = 0;

  # use eval here since we are listing ExtUtils as a prerequisite
  # anyway and so if this does not work we'll still get a message
  # later
  my $flibs = '';
  eval { require ExtUtils::F77; ExtUtils::F77->import };
  if ($@) {
    print "Error determining Fortran library requirements\n";
  } else {
    $flibs = ExtUtils::F77->runtime;
    push(@defines, "-DHAS_UNDERSCORE")
      if ExtUtils::F77->trail_;
  }

  $libs = "$sla_lib $flibs";

} else {
  print "Attempting to build against a C SLALIB library: $sla_lib\n";

  use Devel::CheckLib;
  unless (check_lib(LIBS => $sla_lib,INC=>$sla_inc)) {
    print "You need either Fortan or C version of slalib. See README\n";
    exit 0;
  }

  # no special defines for the C version

  # Just need the math library
  $libs = "$sla_lib -lm";
}

my $file = File::Spec->catfile( "lib", "Astro", "SLA.pm" );

my $build = Module::Build->new
  (
   module_name => "Astro::SLA",
   abstract_from => $file,
   license => "gpl",
   author => [
              'Tim Jenness <tjenness@cpan.org>',
             ],
   version_from => $file,
   meta_merge => {
               resources =>  {
                              repository => "git://github.com/timj/perl-Astro-SLA.git",
                              homepage => "http://github.com/timj/perl-Astro-SLA/tree/master",
                             },
                },
   script_files => [ qw/
                         stime
                       /],
   requires => {
                "Pod::Usage" => 0,
                "Getopt::Long" => 0,
               },
   build_requires => {
                      "Test::More" => 0,
                      "Test::Number::Delta" => 1.0,
                      %build_prereqs,
                     },
   configure_requires => {
                          "Module::Build" => 0.30,
                          %build_prereqs,
                         },
   c_source => "src",  # Only one option so use single string
   extra_compiler_flags => [$sla_inc, @defines],
   extra_linker_flags => $libs,
  );

$build->create_build_script;

