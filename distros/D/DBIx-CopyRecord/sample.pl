#!/usr/bin/perl -w

use strict;
use DBI;
use DBIx::CopyRecord;

my $DBD = 'mysql'; 
                       
my $DB_USER = 'jack';
my $DB_PASS = '';
my $DB_DSN = "DBI:mysql:amsu:localhost";

my $dbh=DBI->connect($DB_DSN, $DB_USER, $DB_PASS,
    { 'RaiseError' => 0, 'AutoCommit' => 1 });

my $CR = DBIx::CopyRecord->new ( $dbh );

my $rv=$CR->copy( {
               parent => {
                            table_name => 'xq9_invoice_master',
                            primary_key => 'invoice_number',
                            primary_key_value => 'NULL',
                            where => 'invoice_number=1' ,
                            override => {
                                          invoice_date => 'NULL',
                                          billed => 'Y' } },
               child =>  [ { table_name => 'xq9_invoice_detail',
                                     primary_key => 'invoice_detail_id',
                                     primary_key_value => 'NULL',
                                     foreign_key => 'invoice_number' },
                           { table_name => 'xq9_ship_to',
                                     primary_key => 'ship_to_id',
                                     primary_key_value => 'NULL',
                                     foreign_key => 'invoice_number' },
                           { table_name => 'xq9_instructions',
                                     primary_key => 'instruction_id',
                                     primary_key_value => 'NULL',
                                     foreign_key => 'invoice_number' } ] } );
print "NEW primary key value:$rv\n";




