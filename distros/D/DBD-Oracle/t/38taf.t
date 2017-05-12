#!perl -w
# $Id$

use DBI;
use DBD::Oracle(qw(:ora_fail_over));
use strict;
#use Devel::Peek qw(SvREFCNT Dump);

use Test::More;
unshift @INC ,'t';
require 'nchar_test_lib.pl';

$| = 1;

# create a database handle
my $dsn = oracle_test_dsn();
my $dbuser = $ENV{ORACLE_USERID} || 'scott/tiger';

my $dbh = eval { DBI->connect($dsn, $dbuser, '',) }
    or plan skip_all => "Unable to connect to Oracle";

$dbh->disconnect;

if ( !$dbh->ora_can_taf ){

    eval {
        $dbh = DBI->connect(
            $dsn, $dbuser, '',
            {ora_taf_function => 'taf'})
    };
    my $ev = $@;
    like($ev, qr/You are attempting to enable TAF/, "'$ev' (expected)");
}
else {
   ok $dbh = DBI->connect($dsn, $dbuser, '',
                          {ora_taf_function=>'taf'});

   is($dbh->{ora_taf_function}, 'taf', 'TAF callback');

   my $x = sub {};
#   diag(SvREFCNT($x));
#   diag(Dump($x));
   $dbh->{ora_taf_function} = $x;
   is(ref($dbh->{ora_taf_function}), 'CODE', 'TAF code ref');

#   diag(SvREFCNT($x));
}

$dbh->disconnect;

done_testing();
