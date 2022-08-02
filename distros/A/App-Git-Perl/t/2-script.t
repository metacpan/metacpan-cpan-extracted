use Test::More;

my $script = "script/git-perl";

#----------------------------------------------------------------------------
# Skip testing on Windows

if ( $ENV{COMSPEC} ) {
  pass("Since using some of the linux cli commands, this script is not intended to use in Windows. Sorry.");
  done_testing();
  exit;
}

#----------------------------------------------------------------------------
# configure environment for testing

my $gitdir = qx{ $script config dir };
chomp($gitdir);
$gitdir = "." if ( not $gitdir );

#----------------------------------------------------------------------------
# Testing 'git perl' / testing script itself

my $test = qx{ $script };
ok( $test =~ /git perl config/, "Script is working properly." ) or BAIL_OUT "Script is NOT working properly!";

#----------------------------------------------------------------------------
# Testing 'git perl recent' / getting data from remote site

$test = qx{ $script recent };
ok( $test =~ / UTC /, "Able to get data from remote site / git perl recent." );

#----------------------------------------------------------------------------
# Testing 'git perl log nonexistedmodule'

$test = qx{ $script log abc123 };
ok( $test =~ /Respository for module 'abc123' does not exist/, "Able to get remote non-existing repository." );

#----------------------------------------------------------------------------
# Testing 'git perl log "NHRNJICA/App-Git-Perl"'

$test = qx{ $script log NHRNJICA/App-Git-Perl };

if ( $test =~ /Author: / ) {
  pass("I can see the content of git log.");
} else {
  fail("git log does not work. I cannot see changes from git log");
}

if ( $test =~ /Cloned into: (.*)/s ) {
  $test=$1;
  chomp($test);
}
ok( $test =~ /App-Git-Perl/, "Able to get remote repository." );

$test = ( -d "$gitdir/App-Git-Perl" );
ok( $test, "Local repository created." );

$test = qx{ $script log App-Git-Perl remove };
ok( $test =~ /Removed repository/, "Able to remove local repository." );

$test = ( ! -d "$gitdir/App-Git-Perl" );
ok( $test, "Local repository successfully removed." );

#----------------------------------------------------------------------------
# Testing "git perl log App::Git::Perl"

$test = qx{ $script log App::Git::Perl };

if ( $test =~ /Author: / ) {
  pass("I can see the content of git log.");
} else {
  fail("git log does not work. I cannot see changes from git log");
}

if ( $test =~ /Cloned into: (.*)/ ) {
  $test=$1;
  chomp($test);
}
ok( $test =~ /App-Git-Perl/, "Able to get remote repository." );

$test = ( -d "$gitdir/App-Git-Perl" );
ok( $test, "Local repository created." );

$test = qx{ $script log App::Git::Perl remove };
ok( $test =~ /Removed repository/, "Able to remove local repository." );

$test = ( ! -d "$gitdir/App-Git-Perl" );
ok( $test, "Local repository successfully removed." );

#----------------------------------------------------------------------------
# Testing 'git perl clone "NHRNJICA/App-Git-Perl"'

$test = qx{ $script clone NHRNJICA/App-Git-Perl };
if ( $test =~ /Cloned into: (.*)/ ) {
  $test=$1;
  chomp($test);
}
ok( $test =~ /App-Git-Perl/, "Able to get remote repository." );

$test = ( -d "$gitdir/App-Git-Perl" );
ok( $test, "Local repository created." );

$test = qx{ $script clone App-Git-Perl remove };
ok( $test =~ /Removed repository/, "Able to remove local repository." );

$test = ( ! -d "$gitdir/App-Git-Perl" );
ok( $test, "Local repository successfully removed." );

#----------------------------------------------------------------------------
# Testing 'git perl clone App::Git::Perl'

$test = qx{ $script clone App::Git::Perl };
if ( $test =~ /Cloned into: (.*)/ ) {
  $test=$1;
  chomp($test);
}
ok( $test =~ /App-Git-Perl/, "Able to get remote repository." );

$test = ( -d "$gitdir/App-Git-Perl" );
ok( $test, "Local repository created." );

$test = qx{ $script clone App-Git-Perl remove };
ok( $test =~ /Removed repository/, "Able to remove local repository." );

$test = ( ! -d "$gitdir/App-Git-Perl" );
ok( $test, "Local repository successfully removed." );

#----------------------------------------------------------------------------
# Testing 'git perl local'

## get at least one repository locally, so we can work with
$test = qx{ $script clone App::Git::Perl };
if ( $test =~ /Cloned into: (.*)/ ) {
  $test=$1;
  chomp($test);
}
ok( $test =~ /App-Git-Perl/, "Able to get remote repository." );

$test = ( -d "$gitdir/App-Git-Perl" );
ok( $test, "Local repository created." );

## Now, real test goes.

$test = qx{ $script local };
ok( $test =~ /^App-Git-Perl/, "Able to read list of local repositories." );

$test = qx{ $script local abc123 };
ok( $test !~ /abc123 /, "If the local repository does not exist, it will be not listed out." );

$test = qx{ $script local App-Git-Perl };
ok( $test =~ /^App-Git-Perl /, "Able to list repository." );

$test = qx{ $script local App-Git-Perl log };
if ( $test =~ /Author: / ) {
  pass("I can see the content of git log.");
} else {
  fail("git log does not work. I cannot see changes from git log");
}

$test = qx{ $script local App-Git-Perl remove };
ok( $test =~ /Removed repository/, "Able to remove local repository." );

$test = ( ! -d "$gitdir/App-Git-Perl" );
ok( $test, "Local repository successfully removed." );

# clone repository if it is not already here
$test = qx{ $script local App::Git::Perl };
if ( $test =~ /Cloned into: (.*)/ ) {
  $test=$1;
  chomp($test);
}
ok( $test =~ /App-Git-Perl/, "Able to get remote repository." );

$test = ( -d "$gitdir/App-Git-Perl" );
ok( $test, "Local repository created." );

$test = qx{ $script local App::Git::Perl remove };
ok( $test =~ /Removed repository/, "Able to remove local repository." );

$test = ( ! -d "$gitdir/App-Git-Perl" );
ok( $test, "Local repository successfully removed." );

#----------------------------------------------------------------------------

#  git perl config                                     = show current config ( from ~/.config/git-perl.conf )
#  git perl config dir                                 = show value of 'dir' from config
#  git perl config dir ~/git/perl                      = set value of 'dir' to '~/git/perl'
#  git perl config --unset dir                         = remove variable 'dir' from config file

$test = qx{ $script config testvariable something };
# no output is expected
ok( $test eq "", "Variable probably created. We will test." );

$test = qx{ $script config testvariable };
chomp($test);
ok( $test eq "something", "Variable successfully saved in config." );

$test = qx{ $script config };
chomp($test);
ok( $test =~ /testvariable=something/, "Variable successfully saved in config." );

$test = qx{ $script config --unset testvariable };
ok( $test eq "", "Variable probably unset/removed. We will test." );

$test = qx{ $script config testvariable };
chomp($test);
ok( $test eq "", "Variable successfully removed from config." );

#----------------------------------------------------------------------------
done_testing();

