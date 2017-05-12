package Module::Build::AstroNova;
use 5.006;
use warnings;
use strict;

use Module::Build;
our @ISA = 'Module::Build';

use File::Spec;
use Config;

our $NovaDir = 'libnova-0.15.0';
our $NovaDirStaticLib = File::Spec->catfile($NovaDir, 'src', '.libs', 'libnova'.$Config::Config{lib_ext});

sub ACTION_code {
  my $self = shift;
  $self->depends_on("libnova");
  $self->depends_on("structs");
  return $self->SUPER::ACTION_code(@_);
}

sub ACTION_patchlibnova {
  my $self = shift;
  if ($^O =~ /bsd/i or $^O =~ /solaris/i) {
    if (not -e File::Spec->catfile($NovaDir, '.cosl_patched')) {
      $self->log_info("Patching libnova with cosl patch...\n");
      system($^X, File::Spec->catdir("buildtools", "cosl_patch.pl"), $NovaDir)
        and die "Failed to patch libnova";
    }
    else {
      $self->log_info("libnova cosl patch already applied\n");
    }
  }
  else {
    $self->log_info("Not patching libnova with cosl patch: Likely not necessary on this OS\n");
  }
}

sub ACTION_libnova {
  my $self = shift;

  if (-f $NovaDirStaticLib) {
    $self->log_info("libnova already built, skipping re-build.\n");
    return 1;
  }
  $self->log_info("Building libnova for static linking...\n");
  
  $self->depends_on("patchlibnova");
 
  my $oldcwd = Cwd::cwd();
  chdir($NovaDir) or die "Failed to chdir to '$NovaDir'";
  system("./configure", "--with-pic") and die "Failed to configure libnova";
  system("make") and die "Failed to compile libnova";
  chdir $oldcwd;
  if (-f $NovaDirStaticLib) {
    $self->log_info("Built libnova and found static library. All is well.\n");
  }
  else {
    die "Tried to build libnova, but the static library isn't where I expected it ($NovaDirStaticLib)";
  }
  return 1;
}

sub ACTION_structs {
  my $self = shift;
  $self->depends_on("libnova");
  $self->log_info("Generating XS/Structs.xs...\n");
  system($^X, File::Spec->catfile("buildtools", "makeNovaClass.pl"))
    and die "Failed to build XS/Structs.xs";
  return 1;
}

1;
