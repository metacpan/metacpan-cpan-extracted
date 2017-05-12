#   Hej, Emacs, give us -*- perl mode here!
#
#   $Id: lib.pl,v 1.1 1998/04/22 17:42:33 joe Exp $
#
#   lib.pl is the file where database specific things should live,
#   whereever possible. For example, you define certain constants
#   here and the like.
#

require 5.003;
use strict;
use vars qw($mdriver $dbdriver $childPid $test_dsn $test_user $test_password
            $verbose);

#
#   DSN being used; do not edit this, edit "$dbdriver.dbtest" instead
#
$ENV{'DBI_DSN'} = "DBI:DBMaker:dbsample" unless $ENV{'DBI_DSN'};
$ENV{'DBI_USER'}= "SYSADM"          unless $ENV{'DBI_USER'};
$ENV{'DBI_PASS'}= ""                unless $ENV{'DBI_PASS'};

$::t = 0;
$::verbose = 0;

sub MyConnect {
  return DBI->connect($ENV{'DBI_DSN'}, $ENV{'DBI_USER'}, $ENV{'DBI_PASS'},
                      {PrintError=>0, AutoCommit=>0});
}

sub Check ($;$$) {
  my($result, $error) = @_;
  ++$::t;
  if ($result) {
    print "ok $::t\n";
    return 1;
  } else {
    printf("not ok $::t%s\n", (defined($error) ? " $error" : ""));
    return 0;
  }
}

sub DbiError {
  print "Test $::t: DBI error $DBI::err, $DBI::errstr\n";
}

1;
