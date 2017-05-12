##!/usr/bin/perl -w
use strict;
# ------------------------------------------------------------------------
use DBI;
print "Program $0 now starting \n";
#
################### Build DSN Less MSSQL Connection Parameters  ####################################################
# my $DSN = 'driver={SQL Server};Server=markchar; database=orders; uid=orderguy; pwd=element;';
my $dbh = DBI->connect()
                or die "Can't connect to databese ", DBI::errstr," \n";
##################################################################################################
print "We have connected successfully to the Database \n";
$dbh->{RaiseError} = 1;  # let DBI handle the call to die
eval {
   $dbh->do("drop table PERL_DBD_TEST");
   $dbh->do("create table PERL_DBD_TEST (
	[OrderID] [int] IDENTITY (1, 1) NOT NULL ,
	[CustomerID] [nchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EmployeeID] [int] NULL ,
	[OrderDate] [datetime] NULL ,
	[RequiredDate] [datetime] NULL ,
	[ShippedDate] [datetime] NULL ,
	[ShipVia] [int] NULL ,
	[Freight] [money] NULL ,
	[ShipName] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ShipAddress] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ShipCity] [nvarchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ShipRegion] [nvarchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ShipPostalCode] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ShipCountry] [nvarchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
   )");
};

# Jeff... IF you comment this out, you should see the following error

# $dbh->{odbc_default_bind_type} = 12; # SQL_VARCHAR for

#      May 18, 2003                  compatibility with older DBD::ODBC
# $dbh->{odbc_default_bind_type} = 0; # **DEFAULT won't work here***
# DBD::ODBC::st execute failed: [Microsoft][ODBC SQL Server Driver]Invalid character value for cast specification (SQL-22018)(DBD: st_execute/SQLExecute err=-1)
# DBD::ODBC::st execute failed: [Microsoft][ODBC SQL Server Driver]Invalid character value for cast specification (SQL-22018)(DBD: st_execute/SQLExecute err=-1)
#

# # # # # # # #  Prepare the Insert into Order Table Statement # # # # # # # # # # #
my   $insert_order_stm = $dbh->prepare ( "
    INSERT INTO PERL_DBD_TEST (
        CustomerID, EmployeeID, OrderDate,
        RequiredDate, ShippedDate, ShipVia,
	ShipName, ShipAddress,
        ShipCity, ShipRegion, ShipPostalCode,
        ShipCountry )
    VALUES (?,?,?,?,?,?,?,?,?,?,?,?)" );


# $dbh->{odbc_default_bind_type} = 0; # SQL_VARCHAR for
  $insert_order_stm->bind_param(1, 0001);
  $insert_order_stm->bind_param(2, 9);
  $insert_order_stm->bind_param(3, "{d '2003-05-16'}" );
  $insert_order_stm->bind_param(4, "{d '2003-06-25'}" );
  $insert_order_stm->bind_param(5, "{d '2003-06-22'}" );
  $insert_order_stm->bind_param(6, 1);
  $insert_order_stm->bind_param(7, "Cust1");
  $insert_order_stm->bind_param(8, "addr 1");
  $insert_order_stm->bind_param(9, "city");
  $insert_order_stm->bind_param(10, "region");
  $insert_order_stm->bind_param(11, "999");
  $insert_order_stm->bind_param(12, "USA");

  my $rc = $insert_order_stm->execute;
  print "Last SQL Return Code from insert to Order Table = $rc \n" ;
  print "Program $0 now ending \n";

  $dbh->disconnect;
