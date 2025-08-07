#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use File::Basename;
use File::Spec::Functions;
use File::Temp;

use Cwd;

use File::chdir;
use Capture::Tiny qw(capture);

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $Ghmulti_Scr = Cwd::abs_path(catfile(dirname(__FILE__), qw(.. script ghmulti)));

{
  my $github_repo = 'https://github.com/klaus-rindfrey/perl-app-ghmulti';
  my $tmp_dir = File::Temp->newdir();
  local $CWD = $tmp_dir;
  mkdir('.ssh');
  open(my $hndl, '>', catfile(qw(.ssh config)));
  print $hndl (do { local $/; <DATA> });
  close($hndl);

  local $ENV{HOME} = $tmp_dir;

  check_error([qw(-c https://github.com/metacpan/metacpan-web)],
             qr!\bmetacpan: user name not in /tmp/[^/]+/.ssh/config\b!);
  check_error([qw(-u https://github.com/user1/repo1.git BLAH)],
              qr/\bToo many arguments BLAH\s+Usage:\s+ghmulti\b/);
  check_error([qw(-u -c)],
              qr/\bToo many options\s+Usage:/);

  my $msg = run_ghmulti([qw(-c https://github.com/klaus-rindfrey/perl-app-ghmulti)]);
  ok(-d catdir(qw(perl-app-ghmulti .git)), 'Local repo has been created');
  like($msg,
       qr/Running:\ git\ config\ user\.email\ "[^"]+rindfrey\@.*?"\n
         Running:\ git\ config\ user\.name\ "Klaus\ Rindfrey"/x,
       'STDOUT output ok');
  {
    local $CWD = 'perl-app-ghmulti';
    check_repo();
  }

  $msg = run_ghmulti([qw(-c https://github.com/klaus-rindfrey/perl-app-ghmulti OTHER_DIR)]);
  ok(-d catdir(qw(OTHER_DIR .git)), 'Local repo has been created');
  like($msg,
       qr/Running:\ git\ config\ user\.email\ "[^"]+rindfrey\@.*?"\n
         Running:\ git\ config\ user\.name\ "Klaus\ Rindfrey"/x,
       'STDOUT output ok');
  {
    local $CWD = 'OTHER_DIR';
    check_repo();
  }

  system(qw(git clone https://github.com/klaus-rindfrey/perl-app-ghmulti CLONED)) == 0
    or die("Error cloning https://github.com/klaus-rindfrey/perl-app-ghmulti");
  {
    local $CWD = 'CLONED';
    is(`git remote get-url origin`,
       "https://github.com/klaus-rindfrey/perl-app-ghmulti\n",
       'remote URL after cloning'
      );
    my $ssg_gh_url = "git\@github-klaus-rindfrey:klaus-rindfrey/perl-app-ghmulti.git";
    is(`$Ghmulti_Scr -u`, "$ssg_gh_url\n", 'Option -u');
    system($Ghmulti_Scr) == 0 or die("Error running $Ghmulti_Scr");
    is(`git remote get-url origin`, "$ssg_gh_url\n", "");
    check_repo();
  }
}

#=============================================================================
done_testing();

#=============================================================================

sub check_error {
  my ($args, $regex) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $prefix = "Error case '@$args'";
  note("$prefix.");
  my ($stdout, $stderr, $exit) = capture { system($Ghmulti_Scr, @$args); };
  ok($exit, "$prefix: non zero exit");
  is($stdout, "", "$prefix: no STDOUT ouput");
  like($stderr, $regex, "$prefix: error message");
}

sub run_ghmulti {
  my ($args) = @_;
  my $cmd_str = "$Ghmulti_Scr,@$args";
  note("Running: $cmd_str");
  my ($stdout, $stderr, $exit) = capture { system($Ghmulti_Scr, @$args); };
  die("Failed running: $cmd_str\nSTDERR: $stderr") if $exit;
  return $stdout;
}


sub check_repo {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is(`git config user.email`, "klaus.rindfrey\@mymail.xy\n", "check repo: user.email");
  is(`git config user.name`, "Klaus Rindfrey\n", "check repo: user.name");
}

#############################################################################

__DATA__


Host github-minimal
#  User: <main@addr.xy>
   HostName github.com
   IdentityFile ~/.ssh/mini
   IdentitiesOnly yes

Host github-klaus-rindfrey
#  User: Klaus Rindfrey <klaus.rindfrey@mymail.xy> <klausrin@cpan.org.eu> additional data
   HostName github.com
   IdentityFile ~/.ssh/jdoe
   IdentitiesOnly yes

Host github-jc
#  User: Jonny Controlletti <main-jc@addr.xy>
   HostName github.com
   IdentityFile ~/.ssh/jc
   IdentitiesOnly yes
