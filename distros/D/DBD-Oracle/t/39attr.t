#!perl -w
# $Id$
#
# Test you can set and retrieve some attributes after connect
# MJE wrote this after discovering the code to set these attributes
# was duplicated in connect/login6 and STORE and it did not need to be
# because DBI passes attributes to STORE for you.
#
use DBI;
use DBD::Oracle(qw(ORA_OCI));
use strict;
#use Devel::Peek qw(SvREFCNT Dump);

use Test::More;
unshift @INC ,'t';
require 'nchar_test_lib.pl';

$| = 1;

my $dsn = oracle_test_dsn();
my $dbuser = $ENV{ORACLE_USERID} || 'scott/tiger';
#use Devel::Leak;
#use Test::LeakTrace;

#no_leaks_ok {
    do_it();
#} -verbose;

sub do_it {
    #my $handle;
    #my $count = Devel::Leak::NoteSV($handle);

    my $dbh = eval { DBI->connect($dsn, $dbuser, '',) }
        or plan skip_all => "Unable to connect to Oracle";

    diag("Oracle version: " . join(".", @{$dbh->func('ora_server_version')}));
    diag("client version: " . ORA_OCI());

  SKIP: {
        my @attrs = (qw(ora_module_name
                        ora_client_info
                        ora_client_identifier
                        ora_action));
        my @attrs112 = (qw(ora_driver_name));

        skip('Oracle OCI too old', 1 + @attrs + @attrs112) if ORA_OCI() < 11;

        foreach my $attr (@attrs) {
            $dbh->{$attr} = 'fred';
            is($dbh->{$attr}, 'fred', "attribute $attr set and retrieved");
        }

      SKIP: {
            skip 'Oracle OCI too old', 1 + @attrs112 if ORA_OCI() < 11.2;

            like($dbh->{ora_driver_name}, qr/DBD/, 'Default driver name');

            foreach my $attr (@attrs) {
                $dbh->{$attr} = 'fred';
                is($dbh->{$attr}, 'fred', "attribute $attr set and retrieved");
            }
        }
    };

    foreach my $attr (qw(ora_oci_success_warn
                         ora_objects)) {
        $dbh->{$attr} = 1;
        is($dbh->{$attr}, 1, "attribute $attr set and retrieved");
    }

    $dbh->disconnect;
    #Devel::Leak::CheckSV($handle);
}

done_testing();
