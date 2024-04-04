## minimal subset of SATest which does the PATH cleaning needed for taint mode
## makes the t/log directory but stops short of doing the calls to catdir and tempdir that fails
## leaving that for the test file to do

package main;

use v5.14.0;

# use strict;
# use warnings;
# use re 'taint';

use Cwd;
use Config;
use File::Path;
use File::Spec;

use POSIX;

use vars qw($RUNNING_ON_WINDOWS);

BEGIN {
  $RUNNING_ON_WINDOWS = ($^O =~ /^(mswin|dos|os2)/oi);
  # Clean PATH so taint doesn't complain
  if (!$RUNNING_ON_WINDOWS) {
    $ENV{'PATH'} = '/bin:/usr/bin:/usr/local/bin';
    # Remove tainted envs, at least ENV used in FreeBSD
    delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
  } else {
    # Windows might need non-system directories in PATH to run a Perl installation
    # The best we can do is clean out obviously bad stuff such as relative paths or \..\
    my @pathdirs = split(';', $ENV{'PATH'});
    $ENV{'PATH'} =
      join(';', # filter for only dirs that are canonical absolute paths that exist
        map {
              my $pathdir = $_;
              $pathdir =~ s/\\*\z//;
              my $abspathdir = File::Spec->canonpath(Cwd::realpath($pathdir)) if (-d $pathdir);
              if (defined $abspathdir) {
                $abspathdir  =~ /^(.*)\z/s;
                $abspathdir = $1; # untaint it
              }
              ((defined $abspathdir) and (lc $pathdir eq lc $abspathdir))?($abspathdir):()
            }
          @pathdirs);
  }
}

sub t_init {
  my $tname = shift;

  (-f "t/test_dir") && chdir("t");        # run from ..
  -f "test_dir"  or die "FATAL: not in test directory?\n";

  mkdir ("log", 0755);
  -d "log" or die "FATAL: failed to create log dir\n";
  chmod (0755, "log"); # set in case log already exists with wrong permissions

  if (!$RUNNING_ON_WINDOWS) {
    untaint_system("chacl -B log 2>/dev/null || setfacl -b log 2>/dev/null"); # remove acls that confuse test
  }

}

# Simple version of untaint_var for internal use
sub untaint_var {
    local($1);
    $_[0] =~ /^(.*)\z/s;
    return $1;
}

# untainted system()
sub untaint_system {
    my @args;
    push @args, untaint_var($_) foreach (@_);
    return system(@args);
}

1;
