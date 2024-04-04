package main;

require v5.14.0;

use Cwd;
use Config;
use File::Basename;
use File::Copy;
use File::Path;
use File::Spec;
use File::Temp qw(tempdir);

use Test::Builder ();
use Test::More    ();

# use POSIX qw(WIFEXITED WIFSIGNALED WIFSTOPPED WEXITSTATUS WTERMSIG WSTOPSIG);

# use vars qw($RUNNING_ON_WINDOWS
#             $SKIP_SETUID_NOBODY_TESTS $SKIP_DNSBL_TESTS
#             $have_inet4 $have_inet6
#             $workdir $siterules $localrules $userrules $userstate
#             $keep_workdir $mainpid);
 use vars qw($workdir $siterules $localrules $userrules $userstate $mainpid);

# BEGIN {
#     $ENV{'PATH'} = '/bin:/usr/bin:/usr/local/bin';
#     # Remove tainted envs, at least ENV used in FreeBSD
#     delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
# }

sub sa_t_init {
  my $tname = shift;
  # $mainpid = $$;

  # if ($config{PERL_PATH}) {
  #   $perl_path = $config{PERL_PATH};
  # }
  # elsif ($^X =~ m|^/|) {
  #   $perl_path = $^X;
  # }
  # else {
  #   $perl_path = $Config{perlpath};
  #   $perl_path =~ s|/[^/]*$|/$^X|;
  # }

  # $perl_cmd  = $perl_path;

  # if ($ENV{'PERL5OPT'}) {
  #   my $o = $ENV{'PERL5OPT'};
  #   if ($o =~ /(Devel::Cover)/) {
  #     warn "# setting TEST_PERL_TAINT=no to avoid lack of taint-safety in $1\n";
  #     $ENV{'TEST_PERL_TAINT'} = 'no';
  #   }
  #   $perl_cmd .= " \"$o\"";
  # }

  # $perl_cmd .= " -T" if !defined($ENV{'TEST_PERL_TAINT'}) or $ENV{'TEST_PERL_TAINT'} ne 'no';
  # $perl_cmd .= " -w" if !defined($ENV{'TEST_PERL_WARN'})  or $ENV{'TEST_PERL_WARN'}  ne 'no';

  my @pathdirs = @INC;
  if ($ENV{'PERL5LIB'}) {
    @pathdirs = split($Config{path_sep}, $ENV{'PERL5LIB'});
  }
  my $inc_opts =
    join(' -I', # filter for only dirs that are absolute paths that exist, then canonicalize them
      map {
            my $pathdir = $_;
            my $canonpathdir = File::Spec->canonpath(Cwd::realpath($pathdir)) if ((-d $pathdir) and File::Spec->file_name_is_absolute($pathdir));
            if (defined $canonpathdir) {
               $canonpathdir =~ /^(.*)\z/s;
               $canonpathdir = $1; # untaint it
            }
            ((defined $canonpathdir))?($canonpathdir):()
          }
         @pathdirs);
  # $perl_cmd .= " -I$inc_opts" if ($inc_opts);
  
  # $scr = $ENV{'SPAMASSASSIN_SCRIPT'};
  # $scr ||= "$perl_cmd ../spamassassin.raw";

  # $salearn = $ENV{'SALEARN_SCRIPT'};
  # $salearn ||= "$perl_cmd ../sa-learn.raw";

  # $saawl = $ENV{'SAAWL_SCRIPT'};
  # $saawl ||= "$perl_cmd ../sa-awl";

  (-f "t/test_dir") && chdir("t");        # run from ..
  -f "test_dir"  or die "FATAL: not in test directory?\n";

  mkdir ("log", 0755);
  -d "log" or die "FATAL: failed to create log dir\n";
  chmod (0755, "log"); # set in case log already exists with wrong permissions

  ##########
  ### Test return here but keep some code that comes after to be compiled
  return if $tname;

  mkdir($siterules) or die "FATAL: failed to create $siterules\n";
  mkdir($localrules) or die "FATAL: failed to create $localrules\n";
  open(OUT, ">$userrules") or die "FATAL: failed to create $userrules\n";
  close(OUT);
  mkdir($userstate) or die "FATAL: failed to create $userstate\n";

}

1;
