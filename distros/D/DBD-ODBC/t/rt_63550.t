#!/usr/bin/perl -w -I./t
#
# rt_53550 - check Statement is accessible in error handler from do method
#
use Test::More;
use strict;

use DBI qw(:sql_types);
use_ok('ODBCTEST');

eval "require Test::NoWarnings";
my $has_test_nowarnings = ($@ ? undef : 1);

my $dbh;

BEGIN {
   if (!defined $ENV{DBI_DSN}) {
      plan skip_all => "DBI_DSN is undefined";
   }
}

END {
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings);
    done_testing();
}

$dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}
$dbh->{RaiseError} = 0;
$dbh->{PrintError} = 0;
$dbh->{ShowErrorStatement} = 0;

sub _err_handler {

    my ($error, $h) = @_;

    ok(defined($h->{Statement}), 'Statement is defined');

    return 0;

}
$dbh->{HandleError} = \&_err_handler;

$dbh->do("select * from PERL_DBD_RT63550");


