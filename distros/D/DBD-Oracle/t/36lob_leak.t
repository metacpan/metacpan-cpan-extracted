#!perl -w

##----------------------------------------------------------------------------
## 36lob_leak.pl
## By Martin Evans, Easysoft Limited
##----------------------------------------------------------------------------
## Test we are not leaking temporary lobs
##----------------------------------------------------------------------------

use Test::More;

use DBI;
use Config;
use DBD::Oracle qw(:ora_types);
use strict;
use warnings;
use Data::Dumper;

unshift @INC ,'t';
require 'nchar_test_lib.pl';

$| = 1;

my $dsn = oracle_test_dsn();
my $dbuser = $ENV{ORACLE_USERID} || 'scott/tiger';
my $dbh = DBI->connect($dsn, $dbuser, '',,{
                           PrintError => 0,
                       });

if ($dbh) {
   plan tests => 7;
} else {
   $dbh->{PrintError}=1;
   plan skip_all => "Unable to connect to Oracle";
}

# get SID and cached lobs
# if sid not passed in we run 2 tests, get the sid and the cached lobs
# if sid passed in we run 1 test which is to get the cached lobs
sub get_cached_lobs
{
   my ($dbh, $sid) = @_;
   my $cached_lobs;

   if (!defined($sid)) {
     SKIP: {
           eval {
               ($sid) = $dbh->selectrow_array(
                   q/select sid from v$session where audsid =
SYS_CONTEXT('userenv', 'sessionid')/);
           };
           skip 'unable to find sid', 2 if ($@ || !defined($sid));

           pass("found sid $sid");
       };
   }
   if (defined($sid)) {
     SKIP: {
           eval {
               $cached_lobs = $dbh->selectrow_array(
                   q/select CACHE_LOBS from V$TEMPORARY_LOBS where sid
= ?/, undef, $sid);
           };
           skip 'unable to find cached lobs', 1
               if ($@ || !defined($cached_lobs));
           pass("found $cached_lobs cached lobs");
       };
   }
   return ($sid, $cached_lobs);
}

sub setup_test
{
   my ($h) = @_;
   my ($sth, $ev);

   my $fn = 'p_DBD_Oracle_drop_me';

   my $createproc = << "EOT";
CREATE OR REPLACE FUNCTION $fn(pc IN CLOB) RETURN NUMBER AS
BEGIN
   NULL;
   RETURN 0;
END;
EOT

   eval {$h->do($createproc);};
   BAIL_OUT("Failed to create test function - $@") if $@;
   pass("created test function");

   return $fn;
}

sub call_func
{
   my ($dbh, $function, $how) = @_;

   eval {
       my $sth;
       my $sql = qq/BEGIN ? := $function(?); END;/;
       if ($how eq 'prepare') {
           $sth = $dbh->prepare($sql) or die($dbh->errstr);
       } elsif ($how eq 'prepare_cached') {
           $sth = $dbh->prepare_cached($sql) or die($dbh->errstr);
       } else {
           BAIL_OUT("Unknown prepare type $how");
       }
       $sth->{RaiseError} = 1;

       BAIL_OUT("Cannot prepare a call to $function") if !$sth;

       my ($return, $clob);
       $clob = 'x' x 1000;
       $sth->bind_param_inout(1, \$return, 10);
       $sth->bind_param(2, $clob, {ora_type => ORA_CLOB});
       $sth->execute;
   };
   BAIL_OUT("Cannot call $function successfully") if $@;
}


my ($sid, $cached_lobs);
my ($function);
SKIP: {
   ($sid, $cached_lobs) = get_cached_lobs($dbh); # 1 2
   skip 'Cannot find sid/cached lobs', 5 if !defined($cached_lobs);

   $function = setup_test($dbh); # 3
   my $new_cached_lobs;

   foreach my $type (qw(prepare prepare_cached)) {
       for my $count(1..100) {
           call_func($dbh, $function, $type);
       };
       ($sid, $new_cached_lobs) = get_cached_lobs($dbh, $sid);

       # we expect to leak 1 temporary lob as the last statement is
       # cached and the temp lob is not thrown away until you next
       # execute
       if ($new_cached_lobs > ($cached_lobs + 1)) {
           diag("Looks like we might be leaking temporary lobs from
$type");
           fail("old cached lobs: $cached_lobs " .
                    "new cached lobs: $new_cached_lobs");
       } else {
           pass("Not leaking temporary lobs on $type");
       }
       $cached_lobs = $new_cached_lobs;
   }

};

END {
   if ($dbh) {
       local $dbh->{PrintError} = 0;
       local $dbh->{RaiseError} = 1;
       if ($function){
          eval {$dbh->do(qq/drop function $function/);};
          if ($@) {
             diag("function p_DBD_Oracle_drop_me possibly not dropped" .
                    "- check - $@\n") if $dbh->err ne '4043';
          } else {
             note("function p_DBD_Oracle_drop_me dropped");
          }
       }
   }
}
