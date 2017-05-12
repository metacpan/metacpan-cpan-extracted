use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# 
# test if libgramofile is installed!
#

unless (have_libgramofile()) {
  print STDERR <<DEATH;
libgramofile not found
Try setting LIBS value on the command line
Or get libgramofile from 
  https://sourceforge.net/project/showfiles.php?group_id=76091
If you install a Debian package, make sure you also install 
the -dev package, as this is where the headers (.h files) are.
DEATH
exit 0; # 0 recommended by http://cpantest.grango.org (Notes for CPAN Authors)
}

WriteMakefile(
  'NAME'		=> 'Audio::Gramofile',
  'VERSION_FROM'	=> 'Gramofile.pm', # finds $VERSION
  'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
  ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM => 'Gramofile.pm', # retrieve abstract from module
     AUTHOR     => 'Bob Wilkinson <bob@fourtheye.org>') : ()),
  'LIBS'            => ['-lgramofile'], # e.g., '-lm'
  'DEFINE'		=> '-DLIBRARY', # e.g., '-DHAVE_SOMETHING'
);

# below shamelessly stolen from XML::LibXMLs Makefile.PL

use Config;
#use Cwd;
#use Symbol;
use File::Spec;

use vars qw/$DEVNULL/;

BEGIN {
  $DEVNULL = eval { File::Spec->devnull };
  if ($@) { $DEVNULL = '/dev/null' }
}

sub rm_fr {
  my @files = @_;
  my @realfiles;
  foreach (@files) {
    push @realfiles, glob($_);
  }
  foreach my $file (@realfiles) {
    if (-d $file) {
      rm_fr("$file/*");
      rm_fr("$file/.exists");
      rmdir($file) || die "Couldn't remove $file: $!";
    } else {
      chmod(0777, $file);
      unlink($file);
    }
  }
}

sub xsystem {
  my $command = shift;
  if ($DEBUG) {
    print $command, "\n";
    if (system($command) != 0) {
      die "system call to '$command' failed";
    }
    return 1;
  }
  open(OLDOUT, ">&STDOUT");
  open(OLDERR, ">&STDERR");
  open(STDOUT, ">$DEVNULL");
  open(STDERR, ">$DEVNULL");
  my $retval = system($command);
  open(STDOUT, ">&OLDOUT");
  open(STDERR, ">&OLDERR");
  if ($retval == -1) {
    die "system call to '$command' failed";
  }
  return !($? >> 8);
}

sub have_libgramofile {
  unless (mkdir(".testlink", 0777)) {
    rm_fr(".testlink");
    mkdir(".testlink", 0777) or die "Cannot create .testlink dir: $!";
  }
  chdir (".testlink");

  open(CFILE, ">mytest.c") or die "Can't open temporary file, $!";
  print CFILE "int main (int argc, char** argv) { tracksplit_main(); return 0; }\n";

  my $retval = xsystem(join (" ", $Config{ccname}, $Config{ccflags}, "-o mytest mytest.c -lgramofile"));
  chdir ("..");
  rm_fr(".testlink");
  return $retval;
}
