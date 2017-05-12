#!/usr/bin/perl

=head1 NAME

DBIx-Array-export-xls.pl - DBIx::Array XLS Export Example

=head1 LIMITATIONS

Oracle SQL Syntax

=cut

use strict;
use warnings;
use DBIx::Array::Export;

my $connect=shift or die("$0 connection account password"); #written for DBD::Oracle
my $user=shift or die("$0 connection account password");
my $pass=shift or die("$0 connection account password");

my $dba=DBIx::Array::Export->new;
$dba->connect($connect, $user, $pass, {AutoCommit=>1, RaiseError=>1});

my $sql=q{SELECT LEVEL AS "Number",
                 TRIM(TO_CHAR(LEVEL, 'rn')) as "Roman Numeral"
            FROM DUAL
      CONNECT BY LEVEL <= ?
        ORDER BY LEVEL};
my $data=$dba->sqlarrayarrayname($sql, 15); #[[Number=>"Roman Numeral"],
                                            # [1=>"i"], [2=>"ii"], ...]

print $dba->xls_arrayarrayname("Roman Numerals"=>$data);
