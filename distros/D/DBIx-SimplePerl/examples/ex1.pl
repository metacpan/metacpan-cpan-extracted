#!/usr/bin/perl

use strict;
use DBIx::SimplePerl;

my $sice;
my $rc;
my $dbname = sprintf "DBIx-SimplePerl.%i.db",$$;
$sice->db_open(
                        'dsn' => "dbi:SQLite:dbname=".$dbname,
                        'dbuser'        => "",
                        'dbpass'        => ""
              );
	
$rc	= $sice->db_create_table(
					 table=>"test1",
					 columns=>{
					 	    name  => "varchar(30)",
						    number=> "integer",
						    fp    => "number"
					 	  }
					);
	if (defined($rc->{success}))
	   {
	     printf "created table\n";
	   }
	  else
	   {
	     die("SQLite db_create_table =".$dbname);
	     exit;
	   }

$sice->db_close;
