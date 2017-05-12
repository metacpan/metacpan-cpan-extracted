#   Hej, Emacs, give us -*- perl mode here!
#
#   $Id: lib.pl 11207 2008-05-07 11:22:16Z capttofu $
#
#   lib.pl is the file where database specific things should live,
#   whereever possible. For example, you define certain constants
#   here and the like.
#
# All this code is subject to being GUTTED soon
#
use strict;
use vars qw($table $dbdriver $childPid $test_dsn $test_user $test_password);
$table= 't1';
$dbdriver= 'drizzle';

$| = 1; # flush stdout asap to keep in sync with stderr

#
#   DSN being used; do not edit this, edit "$dbdriver.dbtest" instead
#


$::COL_NULLABLE = 1;
$::COL_KEY = 2;


my $file;
if (-f ($file = "t/$dbdriver.dbtest")  ||
    -f ($file = "$dbdriver.dbtest")    ||
    -f ($file = "../tests/$dbdriver.dbtest")  ||
    -f ($file = "tests/$dbdriver.dbtest")) {
  eval { require $file; };
  if ($@) {
    print STDERR "Cannot execute $file: $@.\n";
    print "1..0\n";
    exit 0;
  }
  $::test_dsn      = $::test_dsn || $ENV{'DBI_DSN'} || "DBI:$dbdriver:database=test";
  $::test_user     = $::test_user|| $ENV{'DBI_USER'}  ||  '';
  $::test_password = $::test_password || $ENV{'DBI_PASS'}  ||  '';
}
if (-f ($file = "t/$dbdriver.mtest")  ||
    -f ($file = "$dbdriver.mtest")    ||
    -f ($file = "../tests/$dbdriver.mtest")  ||
    -f ($file = "tests/$dbdriver.mtest")) {
  eval { require $file; };
  if ($@) {
    print STDERR "Cannot execute $file: $@.\n";
    print "1..0\n";
    exit 0;
  }
}


# nice function I saw in DBD::Pg test code
sub byte_string {
    my $ret = join( "|" ,unpack( "C*" ,$_[0] ) );
    return $ret;
}

sub SQL_VARCHAR { 12 };
sub SQL_INTEGER { 4 };

sub ErrMsg (@) { print (@_); }
sub ErrMsgF (@) { printf (@_); }


1;
