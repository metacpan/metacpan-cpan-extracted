#
#   Mac::DtfSQL -  A Perl interface (extension) module to the dtF/SQL 2.01 database engine, 
#                  Macintosh edition
#
#
#   This module is Copyright (C) 2000-2002 by
#
#       Thomas Wegner
#
#       Email: wegner_thomas@yahoo.com
#
#   All rights reserved.
#
#	This program is free software. You can redistribute it and/or modify 
#	it under the terms of the Artistic License, distributed with Perl.
#


package Mac::DtfSQL;


use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.


# Make some utility functions available if asked for
@EXPORT    = ();		# we export nothing by default
@EXPORT_OK = ();		# populated by export_ok_tags:

%EXPORT_TAGS = (
	all => [ qw(

	DTF_FALSE
	DTF_TRUE
	
	NULL
	not_NULL
	
	DTFHANDLE_NULL
	
	DTF_MAX_NAME
	DTF_MAX_USERPASS
	DTF_MIN_MAXSIZE
	DTF_MAX_MAXSIZE
	DTF_MAX_FIELDLENGTH
	
	DTF_CF_FILENAME
	DTF_CF_NETWORK
	DTF_CF_FSSPEC
	
	DTF_RT_SEQUENTIAL
	DTF_RT_RANDOM
	
	DTF_ERR_OK
	DTF_ERR_BAD
	DTF_ERR_FATAL
	DTF_ERR_OTHER
	DTF_ERR_BAD_ID
	DTF_ERR_LOCK
	DTF_ERR_NO_SEG
	DTF_ERR_NO_PAGE
	DTF_ERR_NO_BUFFER
	DTF_ERR_IO
	DTF_ERR_FULL
	DTF_ERR_NO_FILE
	DTF_ERR_RANGE
	DTF_ERR_FILE
	DTF_ERR_MEMORY
	DTF_ERR_INTEGRITY
	DTF_ERR_NO_SCAN
	DTF_ERR_NO_MORE_RECORDS
	DTF_ERR_BUFFER_FULL 
	DTF_ERR_EXISTS
	DTF_ERR_DOES_NOT_EXIST
	DTF_ERR_SERVER
	DTF_ERR_CLIENT
	DTF_ERR_SYNC
	DTF_ERR_NET
	DTF_ERR_STOPPED
	DTF_ERR_PASSWORD
	DTF_ERR_ACCESS
	DTF_ERR_DIV_BY_ZERO
	DTF_ERR_CONVERSION
	DTF_ERR_RESOURCE
	DTF_ERR_TM_FULL
	DTF_ERR_VERSION
	DTF_ERR_LOG_READY
	DTF_ERR_SEQUENCE
	DTF_ERR_USER    
	
	DTF_RC_OTHER
	DTF_RC_RESULT_AVAILABLE
	DTF_RC_ROWS_AFFECTED
	
	DTF_ATY_LONG
	DTF_ATY_STRING 
	DTF_ATY_ENUM

	DTF_AT_NONE
	DTF_AT_CODEPAGE
	DTF_EAT_MESSAGEFILE
	DTF_EAT_RESULTS
	DTF_EAT_RESULTPAGES
	DTF_EAT_LOGLEVEL
	DTF_EAT_LOGFILE
	DTF_EAT_XSFILES
	DTF_EAT_VMTYPE
	DTF_EAT_VMPATH 
	DTF_EAT_VMSLOTS
	DTF_EAT_VMFILESLOTS
	DTF_EAT_VMFREEMEM 
	DTF_CAT_TIMEOUT 
	DTF_CAT_RESETADAPTER 
	DTF_CAT_REMOVENETNAME 
	DTF_CAT_NETSYNCDELAY
	DTF_CAT_TRANSACTIONS
	DTF_CAT_CACHEBUFFERS
	DTF_CAT_PAGEALGO 
	DTF_CAT_R4MODE
	DTF_CAT_R4STATE
	DTF_CAT_R4PATH
	DTF_CAT_R4BACKUPPATH
	DTF_CAT_R4LOGFILESIZE
	DTF_CAT_DBTYPE 
	DTF_CAT_DBCREATOR
	DTF_CAT_SRVSETUP
	DTF_CAT_AUTORECOVER
	DTF_TAT_AUTOCOMMIT
	DTF_TAT_RESULTTYPE
	DTF_RAT_TYPE
	DTF_LAT_NAME
	DTF_LAT_TABLENAME
	DTF_LAT_CTYPE
	DTF_LAT_DEFINITION
	DTF_LAT_SIZE
	DTF_LAT_DISPLAYWIDTH
	DTF_LAT_PRECISION
	DTF_LAT_SCALE

	DTF_CT_DEFAULT
	DTF_CT_CHAR
	DTF_CT_UCHAR
	DTF_CT_SHORT 
	DTF_CT_USHORT
	DTF_CT_LONG
	DTF_CT_ULONG 
	DTF_CT_BOOL
	DTF_CT_DOUBLE
	DTF_CT_CSTRING 
	DTF_CT_SQLSTRING 
	DTF_CT_BLOB
	DTF_CT_DATE
	DTF_CT_TIME 
	DTF_CT_TIMESTAMP 
	DTF_CT_DECIMAL
	DTF_CT_COUNT

	DTF_DT_NULL
	DTF_DT_BYTE
	DTF_DT_WORD 
	DTF_DT_LONGWORD
	DTF_DT_CHAR 
	DTF_DT_SHORT
	DTF_DT_LONG 
	DTF_DT_REAL
	DTF_DT_DECIMAL
	DTF_DT_SHORTSTRING
	DTF_DT_BIT
	DTF_DT_DATE
	DTF_DT_TIME 
	DTF_DT_TIMESTAMP
	DTF_DT_COUNT

	DTF_INVALID_COUNT

	AUTO_COMMIT_ON
	AUTO_COMMIT_OFF
	
	DtfConCreate
	DtfTraExecute
	DtfTraExecuteUpdate
	DtfTraExecuteQuery
	DtfEnvCreate
	DtfConCreate
	DtfConQueryStatus
	DtfConCreateDatabase
	DtfConRecoverDatabase
	DtfConConnect
	DtfTraCreate
	DtfHdlGetError
	DtfResColumnCount
	DtfColCreate
	DtfHdlQueryAttribute
	DtfAttrQueryInfo
	DtfColTableName
	DtfColName
	DtfColDestroy
	DtfResMoveToFirstRow
	DtfResGetField
	DtfResMoveToNextRow
	DtfResDestroy
	DtfTraDestroy
	DtfConDestroy
	DtfConDisconnect
	DtfEnvDestroy
	DtfHdlSetAttribute
	DtfConDataLocationCount
	DtfConDataLocation
	DtfConChangeDataLocation
	DtfConAddDataLocation
	DtfConRemoveDataLocation
	DtfColCType	
	DtfResRowCount
	DtfResQueryFieldInfo
	DtfResMoveToRow
	DtfHdlEnumAttribute 
	DtfHdlSetUserData
	DtfHdlQueryUserData
	
	dtf_connect
	dtf_disconnect
	dtf_connectpp
	dtf_disconnectpp 
	)], 
	
); # %EXPORT_TAGS 

Exporter::export_ok_tags('all'); # add :all tag to @EXPORT_OK


$VERSION = '0.3201'; # initial public release, where x.x201 refers to version 2.01 of dtF/SQL

bootstrap Mac::DtfSQL $VERSION;

# Preloaded methods go here.

#--------------------------------------------------------------------------------------------------------- 
#
# API & MODULE CONSTANTS
#
#--------------------------------------------------------------------------------------------------------- 

#
# Various
#

sub DTF_FALSE() 				{ 0 }
sub DTF_TRUE()					{ 1 }

# NULL or not
sub NULL()						{ 0 }
sub not_NULL()					{ 1 }

# NULL handle
sub DTFHANDLE_NULL() 			{ 0 }


#---------------------------------------------------------------------------------------------------------    

#
# Some Dimension Constants
#

#  max length for column and table names (incl. \0)
sub DTF_MAX_NAME() 				{ 25 }

#  max length of user name or password (incl. \0)
sub DTF_MAX_USERPASS()			{ 17 }

#  min and max database file size, in KBytes
sub DTF_MIN_MAXSIZE() 			{ 0x00000800 }  #  ...KB == 2MB
sub DTF_MAX_MAXSIZE()			{ 0x001fe000 } 	#  ...KB == 2GB

# max non-blob fieldlength
sub DTF_MAX_FIELDLENGTH() 		{ 4096 }

#---------------------------------------------------------------------------------------------------------

#
#  Result Type of curser
#

sub DTF_RT_SEQUENTIAL()			{ 0 }
sub DTF_RT_RANDOM()				{ 1 }


#---------------------------------------------------------------------------------------------------------    

#
#  Connection Flags
#

sub DTF_CF_FILENAME()  			{ 0 }  # if set, file name (string)
sub DTF_CF_NETWORK()   			{ 1 }  # if set, network connection (string)
sub DTF_CF_FSSPEC()    			{ 2 }  # if set, filename Mac OS FSSpec record in FSSpec fmt.


#---------------------------------------------------------------------------------------------------------                                  			  
                                  			  
#
# Error/Result Codes
#

sub DTF_ERR_OK()				{ 0 }
sub DTF_ERR_BAD() 				{ 1 }
sub DTF_ERR_FATAL()         	{ 2 }
sub DTF_ERR_OTHER()          	{ 3 }
sub DTF_ERR_BAD_ID()          	{ 4 }
sub DTF_ERR_LOCK()             	{ 5 }
sub DTF_ERR_NO_SEG()           	{ 6 }
sub DTF_ERR_NO_PAGE()         	{ 7 }
sub DTF_ERR_NO_BUFFER()        	{ 8 }
sub DTF_ERR_IO()              	{ 9 }
sub DTF_ERR_FULL()             	{ 10 }
sub DTF_ERR_NO_FILE()          	{ 11 }
sub DTF_ERR_RANGE()            	{ 12 }
sub DTF_ERR_FILE()             	{ 13 }
sub DTF_ERR_MEMORY()          	{ 14 }
sub DTF_ERR_INTEGRITY()        	{ 15 }
sub DTF_ERR_NO_SCAN()         	{ 16 }
sub DTF_ERR_NO_MORE_RECORDS()  	{ 17 }
sub DTF_ERR_BUFFER_FULL()      	{ 18 }
sub DTF_ERR_EXISTS()           	{ 19 }
sub DTF_ERR_DOES_NOT_EXIST()   	{ 20 }
sub DTF_ERR_SERVER()           	{ 21 }
sub DTF_ERR_CLIENT()           	{ 22 }
sub DTF_ERR_SYNC()             	{ 23 }
sub DTF_ERR_NET()              	{ 24 }
sub DTF_ERR_STOPPED()         	{ 25 }
sub DTF_ERR_PASSWORD()         	{ 26 }
sub DTF_ERR_ACCESS()           	{ 27 }
sub DTF_ERR_DIV_BY_ZERO()      	{ 28 }
sub DTF_ERR_CONVERSION()       	{ 29 }
sub DTF_ERR_RESOURCE()         	{ 30 }
sub DTF_ERR_TM_FULL()          	{ 31 }
sub DTF_ERR_VERSION()         	{ 32 }
sub DTF_ERR_LOG_READY()        	{ 33 }
sub DTF_ERR_SEQUENCE()         	{ 34 }

# first user error
sub DTF_ERR_USER()           	{ 64 }

# result class
sub DTF_RC_OTHER()              { 0 }
sub DTF_RC_RESULT_AVAILABLE()   { 1 }
sub DTF_RC_ROWS_AFFECTED()     	{ 2 } 

#---------------------------------------------------------------------------------------------------------

#
# ATTRIBUTES
#

#---------------------------------------------------------------------------------------------------------

# Attribute Types

sub DTF_ATY_LONG()      		{ 0 }
sub DTF_ATY_STRING()    		{ 1 } 
sub DTF_ATY_ENUM()     			{ 2 }


#---------------------------------------------------------------------------------------------------------

#  Attribute ID convention:
#
#  All attribute IDs consist of four bytes. The first byte defines the
#  attributes scope (handle type) and data type, the other three are an
#  abbreviation of the attribute's name.
#
#  first byte:
#    H .. attribute (scope all/undefined)
#    E .. environment attribute
#    C .. connection attribute
#    T .. transaction attribute
#    R .. result attribute
#    L .. column attribute
#

#---------------------------------------------------------------------------------------------------------
#  'invalid' attribute
sub DTF_AT_NONE() 				{ _define_Attribut(ord("\0"), ord("\0"), ord("\0"), ord("\0")) }

#---------------------------------------------------------------------------------------------------------
#  global scope attributes
sub DTF_AT_CODEPAGE()			{ _define_Attribut(ord("H"), ord("C"), ord("P"), ord("g")) }

#---------------------------------------------------------------------------------------------------------
#  environment scope attributes
sub DTF_EAT_MESSAGEFILE()		{ _define_Attribut(ord("E"), ord("M"), ord("s"), ord("F")) }
sub DTF_EAT_RESULTS() 			{ _define_Attribut(ord("E"), ord("R"), ord("e"), ord("s")) }
sub DTF_EAT_RESULTPAGES()		{ _define_Attribut(ord("E"), ord("R"), ord("e"), ord("P")) }
sub DTF_EAT_LOGLEVEL() 			{ _define_Attribut(ord("E"), ord("L"), ord("L"), ord("v")) }
sub DTF_EAT_LOGFILE()			{ _define_Attribut(ord("E"), ord("L"), ord("F"), ord("l")) }
sub DTF_EAT_XSFILES()			{ _define_Attribut(ord("E"), ord("X"), ord("F"), ord("s")) }
sub DTF_EAT_VMTYPE()			{ _define_Attribut(ord("E"), ord("V"), ord("T"), ord("y")) }
sub DTF_EAT_VMPATH()			{ _define_Attribut(ord("E"), ord("V"), ord("P"), ord("t")) }
sub DTF_EAT_VMSLOTS()			{ _define_Attribut(ord("E"), ord("V"), ord("S"), ord("l")) }
sub DTF_EAT_VMFILESLOTS()		{ _define_Attribut(ord("E"), ord("V"), ord("F"), ord("S")) }
sub DTF_EAT_VMFREEMEM()			{ _define_Attribut(ord("E"), ord("V"), ord("F"), ord("M")) }


#---------------------------------------------------------------------------------------------------------
#  connection scope attributes
sub DTF_CAT_TIMEOUT()			{ _define_Attribut(ord("C"), ord("T"), ord("i"), ord("O")) }
sub DTF_CAT_RESETADAPTER()		{ _define_Attribut(ord("C"), ord("R"), ord("A"), ord("d")) }
sub DTF_CAT_REMOVENETNAME()		{ _define_Attribut(ord("C"), ord("R"), ord("N"), ord("N")) }
sub DTF_CAT_NETSYNCDELAY()		{ _define_Attribut(ord("C"), ord("N"), ord("S"), ord("D")) }
sub DTF_CAT_TRANSACTIONS()		{ _define_Attribut(ord("C"), ord("T"), ord("r"), ord("a")) }

sub DTF_CAT_CACHEBUFFERS()		{ _define_Attribut(ord("C"), ord("B"), ord("u"), ord("f")) }
sub DTF_CAT_PAGEALGO() 			{ _define_Attribut(ord("C"), ord("P"), ord("A"), ord("l")) }
sub DTF_CAT_R4MODE() 			{ _define_Attribut(ord("C"), ord("4"), ord("M"), ord("d")) }
sub DTF_CAT_R4STATE() 			{ _define_Attribut(ord("C"), ord("4"), ord("S"), ord("t")) }
sub DTF_CAT_R4PATH() 			{ _define_Attribut(ord("C"), ord("4"), ord("P"), ord("t")) }
sub DTF_CAT_R4BACKUPPATH()		{ _define_Attribut(ord("C"), ord("4"), ord("B"), ord("P")) }
sub DTF_CAT_R4LOGFILESIZE()		{ _define_Attribut(ord("C"), ord("4"), ord("L"), ord("S")) }
sub DTF_CAT_DBTYPE() 			{ _define_Attribut(ord("C"), ord("D"), ord("b"), ord("T")) }
sub DTF_CAT_DBCREATOR()			{ _define_Attribut(ord("C"), ord("D"), ord("b"), ord("C")) }
sub DTF_CAT_SRVSETUP()			{ _define_Attribut(ord("C"), ord("S"), ord("s"), ord("t")) }
sub DTF_CAT_AUTORECOVER()		{ _define_Attribut(ord("C"), ord("A"), ord("R"), ord("c")) }

#---------------------------------------------------------------------------------------------------------
#  transaction scope attributes
sub DTF_TAT_AUTOCOMMIT()		{ _define_Attribut(ord("T"), ord("A"), ord("C"), ord("m")) }
sub DTF_TAT_RESULTTYPE() 		{ _define_Attribut(ord("T"), ord("R"), ord("T"), ord("y")) }

#---------------------------------------------------------------------------------------------------------
#  result scope attributes
sub DTF_RAT_TYPE() 				{ _define_Attribut(ord("R"), ord("T"), ord("y"), ord("p")) }

#---------------------------------------------------------------------------------------------------------
#  column scope attributes
sub DTF_LAT_NAME() 				{ _define_Attribut(ord("L"), ord("N"), ord("a"), ord("m")) }
sub DTF_LAT_TABLENAME()			{ _define_Attribut(ord("L"), ord("T"), ord("N"), ord("m")) }
sub DTF_LAT_CTYPE()				{ _define_Attribut(ord("L"), ord("C"), ord("T"), ord("y")) }
sub DTF_LAT_DEFINITION()		{ _define_Attribut(ord("L"), ord("D"), ord("e"), ord("f")) }
sub DTF_LAT_SIZE()				{ _define_Attribut(ord("L"), ord("S"), ord("i"), ord("z")) }
sub DTF_LAT_DISPLAYWIDTH()		{ _define_Attribut(ord("L"), ord("D"), ord("W"), ord("d")) }
sub DTF_LAT_PRECISION()			{ _define_Attribut(ord("L"), ord("P"), ord("r"), ord("c")) }
sub DTF_LAT_SCALE() 			{ _define_Attribut(ord("L"), ord("S"), ord("c"), ord("l")) }



#---------------------------------------------------------------------------------------------------------    

#
#  C data type IDs
#

sub DTF_CT_DEFAULT() 			{ 0 }  # dtF/SQL datatype
sub DTF_CT_CHAR() 				{ 1 }  # char
sub DTF_CT_UCHAR() 				{ 2 }  # unsigned char
sub DTF_CT_SHORT() 				{ 3 }  # short
sub DTF_CT_USHORT() 			{ 4 }  # unsigned short
sub DTF_CT_LONG() 				{ 5 }  # long
sub DTF_CT_ULONG() 				{ 6 }  # unsigned long
sub DTF_CT_BOOL() 				{ 7 }  # DTFBOOL
sub DTF_CT_DOUBLE() 			{ 8 }  # double
sub DTF_CT_CSTRING() 			{ 9 }  # null-terminated character string
sub DTF_CT_SQLSTRING() 			{ 10 } # like CSTRING but quoted if necessary
sub DTF_CT_BLOB() 				{ 11 } # array of char
sub DTF_CT_DATE() 				{ 13 } # DTFDATE yyyy-mm-dd\0
sub DTF_CT_TIME() 				{ 14 } # DTFTIME hh:mm:ss\0
sub DTF_CT_TIMESTAMP() 			{ 15 } # DTFTIMESTAMP yyyy-mm-dd hh:mm:ss\0
sub DTF_CT_DECIMAL() 			{ 16 } # DTFDECIMAL 
sub DTF_CT_COUNT() 				{ 17 } # (number of DTFCTYPE  enum values)



#---------------------------------------------------------------------------------------------------------    

#
# dtF/SQL data type IDs
#

sub DTF_DT_NULL() 				{ 0 } 
sub DTF_DT_BYTE() 				{ 1 }
sub DTF_DT_WORD() 				{ 2 }
sub DTF_DT_LONGWORD() 			{ 3 }
sub DTF_DT_CHAR() 				{ 4 }
sub DTF_DT_SHORT() 				{ 5 }
sub DTF_DT_LONG() 				{ 6 }
sub DTF_DT_REAL() 				{ 7 }
sub DTF_DT_DECIMAL() 			{ 8 }	# total max 16 digits [xxxx xxxx xxxx . xxxx = (16, 4) ]
										# min 1 digit ahead of dec. point, 0 fraction digits allowd
sub DTF_DT_SHORTSTRING() 		{ 9 }
sub DTF_DT_BIT() 				{ 10 }
sub DTF_DT_DATE() 				{ 11 }	# yyyy-mm-dd
sub DTF_DT_TIME() 				{ 12 }	# hh:mm:ss
sub DTF_DT_TIMESTAMP() 			{ 14 }	# yyyy-mm-dd hh:mm:ss
sub DTF_DT_COUNT() 				{ 15 }


#---------------------------------------------------------------------------------------------------------    

#
# ???
#

sub DTF_INVALID_COUNT() 		{ hex('0xffffffff') }    


#---------------------------------------------------------------------------------------------------------    

#
# AUTO COMMIT ON / OFF
#

# (example:     DtfHdlSetAttribute ($htra, DTF_TAT_AUTOCOMMIT, AUTO_COMMIT_ON);  )

sub AUTO_COMMIT_ON()			{ 'true' }
sub AUTO_COMMIT_OFF() 			{ 'false' }


#---------------------------------------------------------------------------------------------------------    
#
# MODULE FUNCTIONS
#
#---------------------------------------------------------------------------------------------------------    

# this is the pure Perl version of the dtf_connect sub, 
# which has been implemented in C for speed

sub dtf_connectpp {
  my ($dsn, $user, $pass) = @_;
  
  
  # these 5 vars are the return values (a list)
  my $henv = DTFHANDLE_NULL; 	# environment handle
  my $hcon = DTFHANDLE_NULL; 	# connection handle
  my $htra = DTFHANDLE_NULL; 	# transaction handle
  my $err = DTF_ERR_OK;			# error code
  my $errstr = '';				# error string
  

  my $connected; 	# connected flag
  my $dbExists;  	# dbExists flag
  my $dbConsistent; # dbConsistent flag
  
  my $network = 0; 	# indicates a network connection


  #  First, we always need an environment handle before
  #  we are able to do anything else.
  
  # NOTE
  # Currently, the number of environment handles which may exist at a time is restricted to one.
 
  if ( ($err = DtfEnvCreate($henv) ) != DTF_ERR_OK) {
  	$errstr = "ERROR(dtf_connect): Can't create environment";
	$henv = DTFHANDLE_NULL;
    return ( $henv, $hcon, $htra, $err, $errstr );
  }

  # print "Ok, environment handle created ...\n";

  #  When the environment handle (henv) was created successfully,  a connection handle
  #  can be created as the environment handle's *dependent* handle.
  # 
  #  The parameter $dsn (DSN = data source name) contains for the single-user version   
  #  of dtF/SQL the database's partial or fully qualified path ($flags = DTF_CF_FILENAME),
  #  for example "MacHD:path:to:DB:TESTDB.dtF", for the multi-user verion it contains
  #  a server specification, for example "tcp:host/port" ($flags = DTF_CF_NETWORK).

  # NOTE
  # Currently, only a single connection can be created on every environment handle.
  
  
  if ( $dsn  =~ /tcp:/ ) { # network, please
    $network = 1;
  	$err = DtfConCreate($henv, $dsn, DTF_CF_NETWORK, $hcon);
  } else { # local
  	$err = DtfConCreate($henv, $dsn, DTF_CF_FILENAME, $hcon);
  }

  if ($err != DTF_ERR_OK) {
    $errstr = "ERROR(dtf_connect): Can't create connection to " . $dsn;
	# clear up things
	# at this point, $henv has successfully been created, thus dispose this handle
	DtfEnvDestroy ($henv);
	$henv = DTFHANDLE_NULL;
	$hcon = DTFHANDLE_NULL;
    return ( $henv, $hcon, $htra, $err, $errstr );
  }

  # print "Ok, connection handle created ...\n";
  
  #  This function queries some information about the just established connection

  $connected = NULL; 
  $dbExists = not_NULL; # not NULL is important if you want to get back a result value
  $dbConsistent = not_NULL;	
  if ( ($err = DtfConQueryStatus($hcon, $connected, $dbExists, $dbConsistent) ) != DTF_ERR_OK) {
    $errstr = "ERROR(dtf_connect): Can't query connection status"; 
	# clear up things
	# at this point, $henv and $hcon have successfully been created, thus dispose these handles
	DtfConDestroy ($hcon);
	DtfEnvDestroy ($henv);
	$henv = DTFHANDLE_NULL;
	$hcon = DTFHANDLE_NULL;
    return ( $henv, $hcon, $htra, $err, $errstr );
  }

  # Please note: $connected doesn't work as one might expect. It only says, whether a *connection handle*  
  # hcon is in connected state or not, but it doesn't inform you, whether the *database* you want to 
  # connect to is already in connected state (or not) -- this is a bit odd, isn't it?

  if (! $dbExists) {
  	$err = DTF_ERR_DOES_NOT_EXIST;
    $errstr = "ERROR(dtf_connect): Database " . $dsn . " does not exist";
	# clear up things
	# at this point, $henv and $hcon have successfully been created, thus dispose these handles
	DtfConDestroy ($hcon);
	DtfEnvDestroy ($henv);
	$henv = DTFHANDLE_NULL;
	$hcon = DTFHANDLE_NULL;
    return ( $henv, $hcon, $htra, $err, $errstr );
  }

  # NOTE
  # 	The following has only been tested locally (single-user), since the dtf/SQL server doesn't work
  #     as expected and a network connection currently isn't possible.

  # If the database you want to connect to is already in connected state by another program, $dbConsistent
  # will be set to false (not consistent). $dbConsistent is also false if the database needs recovery. The
  # best thing we can do, is trying to recover the database. If this fails, either the database can't be
  # recovered (because its badly damaged), or the database is already in connected state (but not 
  # inconsistent). Because we cannot distinguish between these cases, the error message mentions both.
  
  if (! $dbConsistent) {
	if (! $network) {
    	#  In single-user version we try to recover the database
    	#  if it was detected to be inconsistent.
    	
    	# print "Trying to recover database ...\n";
    	if ( ($err = DtfConRecoverDatabase($hcon) ) != DTF_ERR_OK) {
     	 	$errstr = "ERROR(dtf_connect): The database " . $dsn . " is either already in connected state or \n"
						. "is inconsistent and could not be recovered";
			# clear up things
			# at this point, $henv and $hcon have successfully been created, thus dispose these handles
			DtfConDestroy ($hcon);
			DtfEnvDestroy ($henv);
			$henv = DTFHANDLE_NULL;
			$hcon = DTFHANDLE_NULL;
     	 	return ( $henv, $hcon, $htra, $err, $errstr );
    	} 
    	
    	# print "Ok, recovered.\n";
		
  	} else { # can't recover in a network, so give back an error
  		$err = DTF_ERR_FATAL;
  		$errstr = "ERROR(dtf_connect): The database " . $dsn . " is either already in connected state or \n"
					. "is inconsistent and could not be recovered in a server connection";
		# clear up things
		# at this point, $henv and $hcon have successfully been created, thus dispose these handles
		DtfConDestroy ($hcon);
		DtfEnvDestroy ($henv);
		$henv = DTFHANDLE_NULL;
		$hcon = DTFHANDLE_NULL;
  		return ( $henv, $hcon, $htra, $err, $errstr );
  	
  	}
  }

  #
  #  Since at this point of execution the database exists
  #  and is in consistent state, we are able to establish
  #  the connection.
  #
  
  
  if ( ($err = DtfConConnect($hcon, $user, $pass) ) != DTF_ERR_OK) {
    $errstr = "ERROR(dtf_connect): Can't connect as " . $user;
	# clear up things
	# at this point, $henv and $hcon have successfully been created, thus dispose these handles
	DtfConDestroy ($hcon);
	DtfEnvDestroy ($henv);
	$henv = DTFHANDLE_NULL;
	$hcon = DTFHANDLE_NULL;
  	return ( $henv, $hcon, $htra, $err, $errstr );
  }
  # print "Ok, connected as user $user ...\n";

  #  We are connected, now create a transaction we are able
  #  to execute SQL statements with.

  # NOTE
  # 	The maximum number of concurrent transactions may be modified by
  # 	setting the connection handle attribute DTF_CAT_TRANSACTIONS. The
  # 	default value of this attribute is 1.
  
  
  if ($err = DtfTraCreate( $hcon, $htra ) != DTF_ERR_OK) {
    $errstr = "ERROR(dtf_connect): Can't create transaction";	
	# clear up things
	DtfConDisconnect ($hcon); # first, disconnect the handle
	# at this point, $henv and $hcon have successfully been created, thus dispose these handles
	DtfConDestroy ($hcon);
	DtfEnvDestroy ($henv);
	$henv = DTFHANDLE_NULL;
	$hcon = DTFHANDLE_NULL;
	$htra = DTFHANDLE_NULL;
  	return ( $henv, $hcon, $htra, $err, $errstr );
  }
  
  # print "Ok, transaction started.\n\n";
  
 # everything is fine here
 
 return ( $henv, $hcon, $htra, $err, $errstr );
  
}#sub dtf_connectpp




#---------------------------------------------------------------------------------------------------------    

# this is the pure Perl version of the dtf_disconnect sub, 
# which has been implemented in C for speed

sub dtf_disconnectpp {

  my ($henv, $hcon, $htra) = @_;
  my ($err, $errstr) = (DTF_ERR_OK, '');

  if ($htra != DTFHANDLE_NULL) {
    if ( ($err = DtfTraDestroy($htra) ) != DTF_ERR_OK) {
		$errstr = "ERROR(dtf_disconnect): Can't destroy transaction handle";
		return ($err, $errstr);
	}
  }#if htra

  if ($hcon != DTFHANDLE_NULL) {
     my $connected = not_NULL; # not NULL is important
     my $dbExists = NULL;
     my $dbConsistent = NULL;
	
    if ( ($err = DtfConQueryStatus($hcon, $connected, $dbExists, $dbConsistent) ) != DTF_ERR_OK) {
		$errstr = "ERROR(dtf_disconnect): Can't query connection status";
		return ($err, $errstr);
	}

    if ($connected) { # connected as user X; (aka login)
      if ( ($err = DtfConDisconnect($hcon) ) != DTF_ERR_OK) {
	  	$errstr = "ERROR(dtf_disconnect): User can't disconnect (logout)";
	  	return ($err, $errstr);
	  }
    }

    if ( ($err = DtfConDestroy($hcon) ) != DTF_ERR_OK) {
		$errstr = "ERROR(dtf_disconnect): Can't destroy connection handle";
		return ($err, $errstr);
  	}
  }#if hcon

  if ($henv != DTFHANDLE_NULL) {
    if ( ($err = DtfEnvDestroy($henv) ) != DTF_ERR_OK) {
		$errstr = "ERROR(dtf_disconnect): Can't destroy environment handle";
		return ($err, $errstr);
  	}
  }#if henv
  
  # everything is fine here
  return ($err, $errstr);

}#sub dtf_disconnectpp




#---------------------------------------------------------------------------------------------------------    



# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__


=head1 NAME

Mac::DtfSQL - A Perl interface module to the dtF/SQL 2.01 database engine, Macintosh edition

=head1 SYNOPSIS

  use Mac::DtfSQL qw(:all); # we export nothing by default
  
  $dsn = 'MacHD:path:to:DB:SampleDB.dtf'; # single-user version
  # or
  $dsn = 'tcp:host/port'; # multi-user/network version
  
  # Note: The dtF/SQL database server may not work as expected, see the
  # "dtF/SQL 2.01(KNOWN) LIMITATIONS" section.
  
  $user = 'dtfadm';
  $password = 'dtfadm';
  
  ($henv, $hcon, $htra, $err, $errstr) = dtf_connect ($dsn, $user, $password);
  
  # Everything in between is too complicated for a synopsis. Please read the  
  # "API CONSTANTS", "API FUNCTIONS", "MODULE CONSTANTS", "MODULE FUNCTIONS" 
  # sections.
  
  ($err, $errstr) = dtf_disconnect ($henv, $hcon, $htra);



  #     
  # Fixed Point Numbers (Decimals)
  #
  
  $dec = Mac::DtfSQL->new_decimal; # new object
  
  $dec->from_string('5500.40'); # assign value from string
  $dec->from_long(150000); # assign value from long integer
  if ( $dec->from_string('9999999999.99') ) { ... } # check if string was successfully converted 
    
  print "value = " , $dec->as_string , "\n"; # convert to string
  $doubleVal = $dec->to_double; # convert to double
  
  if ($dec->is_valid) { ... } # check if decimal is valid
  
  $scale = $dec->get_scale; # get scale
  $dec->set_scale($scale);  # set scale
  
  $dec->assign($dec2); # $dec = $dec2
  
  $dec->add($dec2); # $dec = $dec + $dec2
  $dec->sub($dec2); # $dec = $dec - $dec2
  $dec->mul($dec2); # $dec = $dec * $dec2
  $dec->div($dec2); # $dec = $dec / $dec2
  
  $dec->abs; # absolut value 
  
  if ( $dec->equal($dec2) ) {...};         # $dec == $dec2 ?
  if ( $dec->greater($dec2) ) {...};       # $dec >  $dec2 ?
  if ( $dec->greater_equal($dec2) ) {...}; # $dec >= $dec2 ?
  if ( $dec->less($dec2) ) {...};          # $dec <  $dec2 ?
  if ( $dec->less_equal($dec2) ) {...};    # $dec <= $dec2 ?
  

=head1 DESCRIPTION

This (extension) module is a Perl interface to the dtF/SQL 2.01 database engine, Macintosh
edition. dtF/SQL is a relational database engine for Mac OS, Windows 95/NT, and several Unix 
platforms from sLAB Banzhaf & Soltau oHG (http://www.slab.de/), Boeblingen, Germany. Best of 
all, it's free for non-commercial use. The database engine is provided as a linkable (static 
or shared) library. The dtF/SQL database implements an impressive set of ANSI SQL-92 
functionality. It also supports the BLOB (binary large objects) data type which is an 
arbitrarily large binary stream of data such as an image or a numeric array of data values 
(but the module doesn't support this feature yet). The dtF/SQL database engine supports both 
local and remote retrieval and is really fast.  

The interface is very C-ish, i.e. it tries to match the C API for the dtF/SQL database as closely 
as possible -- with the exception of handling decimals, see below. By doing this, there is no 
need to completely rewrite the API documentation that comes with the distribution of dtF/SQL. 
Instead, the author of this module will only describe the differences -- and for the rest refers 
the reader to the original documentation.


=head2 dtF/SQL SPECIFICATION

The dtF/SQL 2.01 database specification (from their web site):

   + Databases up to 32GB 
   + Relational data up to 512MB 
   + Index data up to 512MB 
   + String data types: CHAR, VARCHAR, SHORTSTRING (max. 4095 chars) 
   + Fixed point decimal types: DECIMAL(precision, scale) 
   + Floating point decimal types: FLOAT, REAL, DOUBLE 
   + Integer types: BYTE, WORD, SHORT, LONGWORD, LONG, INTEGER 
   + Date/Time types: DATE, TIME - Binary types: BLOB 
   + up to 239 database tables 
   + up to 128 columns per table 
   + number of rows per table limited by storage only 
   + number of indexes per table limited by storage only 
   + up to 63 users 
   + up to 63 concurrent transactions 
   + multiple transactions per client 
   + data is stored packed 
   + data is stored scrambled to prevent file inspection in single user version

There are limitations, though. dtF/SQL is designed as an embedded database for product 
developers and, as you might guess, it is not a full featured RDBMS. The dtF/SQL database 
engine doesn't offer prepared statements, stored procedures or user defined triggers.
In addition, the following limitations are documented in the SQL-Reference manual:

   + union, intersect and minus only work correctly when applied to results 
     that are derived from the same original tables.
   + select order by t1.a, t2.a is evaluated equivalent to select order by
     t2.a, t1.a when t1 and t2 refer to the same table.
   + group by supports only one column.
   + Subselects are not implemented.
   + Views are not implemented.
   + Schemas are not implemented.

When considering non-implemented features, always consider that dtF/SQL is not designed as a 
large-scale enterprise RDBMS.

=head2 FOR THE REST OF US

The state of free or nearly free SQL databases on the Macintosh isn't great (see http://www.macsql.com/links.html 
and http://www.lilback.com/macsql/ for example). There is no MySQL or mSQL database available for 
a Mac running Mac OS 7.x/8.x/9.x (and probably there will never be). Things are getting better with Mac OS X, finally 
-- it's grounded on Unix. But this doesn't help users running classic Mac OS. This module should help to 
alleviate the situation. 

This module should run on a PowerPC Macintosh with Mac OS 7.x/8.x/9.x right out of the box. Unfortunately, users 
of a 68K Mac are a bit out of luck, because I cannot provide a pre-built version for them. One will need a 
Metrowerks Codewarrior compiler and linker to build a version for 68K Macs (see the MODULE ARCHITECTURE section 
for details). 



The module has been developed on a Mac, it has been tested on a Mac and it runs on a Mac. However, 
dtF/SQL is available for other platforms too. At the moment, I see no reason why this module shouldn't 
run (after rebuilding, of course) on these other platforms. But I haven't tested this.

This module could be used stand-alone, if you like (the C<browser.pl> sample makes use of this). But primarily it 
is intended as the base for the DBD::DtfSQLmac driver for DBI (which, at a higher abstraction level, offers 
a standard Perl API to relational databases). Now it's possible to seriously play with DBI, not being 
restricted to DBD::CSV, which, after all, isn't the same as working with a real relational database.


=head1 MODULE ARCHITECTURE

This is an extension module, which has been pre-built (PPC only) under Apple's MPW as a shared library 
that will be loaded by MacPerl. Thus, you don't need to bother with MPW if you don't like. Note that the 
pre-built library C<DtfSQL> is useless without the dtF/SQL 2.01 shared library C<dtFPPCSV2.8K.shlb> it
depends on. I've chosen to build the extension as a shared library that *depends* on another shared library 
mainly for two reasons:



=over 0

1. The libraries that come with dtF/SQL 2.01 are Codewarrior libraries. The static libraries can't be
used with MPW. The shared libraries instead use a common format, thus they can be used with MPW too.

2. Things are separated. You can always distinguish between the part, that falls under the terms of the 
Perl Artistic License (this module), and the part, that falls under the terms of the sLAB License Agreement.
I<Note that I do not redistribute any of the material that comes with the dtF/SQL 2.01 distribution.>

=back

Unfortunately, there is no shared library for CFM 68K Macs. Users of a CFM 68K Mac running MacPerl 5.2.0r4
will definitely need the Metrowerks Codewarrior IDE (Pro 2 or higher) to build the Perl extension library (by 
linking against the static library C<dtF68KSV2.8K.lib>).

Owners of a PowerPC Mac with Metrowerks Codewarrior installed could of course link against the static library that 
comes with the dtF/SQL 2.01 distribution (C<dtFPPCSV2.8K.lib>) in the build process, thus ending up with a single
shared library.

However, be aware that support for dynamic loading of shared libraries has been dropped for the 68K versions of 
the new MacPerl 5.6.1 (and higher) tool and application. Hence, you will have to link the Mac::DtfSQL extension 
I<statically> into your MacPerl 5.6.1 binary.


=head1 INSTALLATION

This module is bundled with the DBD::DtfSQLmac module, a driver for the DBI module, and should be installed as part 
of it. See the installation instructions in the DBD::DtfSQLmac module documentation for details. However, if you, for 
any reason, don't want to install the DBI driver, this module could also be used stand-alone. Follow the installation 
instructions in the DBD::DtfSQLmac module and then delete the DBD::DtfSQLmac module from your Perl library (by 
default it's located in the C<site_perl> folder).

If you use the pre-built version of this module or you've built this module as a shared library
that depends on the dtF/SQL 2.01 shared library C<dtFPPCSV2.8K.shlb>, then this module needs to know where the dtF/SQL 
2.01 shared library is located on your harddisk. Either put the dtF/SQL 2.01 shared library C<dtFPPCSV2.8K.shlb> 
(or at least an alias to it) in the *same* folder as the shared library C<DtfSQL> built from this extension module 
(by default the folder is C<:MacPerlƒ:site_perl:MacPPC:auto:Mac:DtfSQL:>) or put the dtF/SQL 2.01 shared library in 
the *system extensions* folder.

After you've installed this module and the dtF/SQL 2.01 shared library, you may want to run the test.pl script, to see 
if the module loads properly (note that only test #1 is dedicated to this module, the remaining tests are DBI specific).
Then you are able to run the scripts C<createSampleDB.pl> (creates the sample database C<SampleDB.dtf>), C<browser.pl> 
(an interactive tool for querying the database with SQL statements) and C<decimals.pl> (tests thedecimal object methods), 
located in the samples folder. 


=head1 MEMORY REQUIREMENTS

 A minimum of 10MB / 11MB of RAM assigned to the MacPerl 5.2.0r4 / 5.6.1 application.
 A minimum of 11MB / 12MB of RAM assigned to the MPW Shell for running the MacPerl 5.2.0r4 / 5.6.1 tool.

This module requires quite a bit of RAM, as noted above. These values were determined by running the DBI test suite 
that comes with this module. They should be regarded as the absolute minimum. The MacPerl 5.6.1 application and tool 
will need at least 1MB more RAM than the MacPerl 5.2.0r4 application and tool. However, as your database grows, be 
prepared to assign more memory to MacPerl. If the memory assigned is less than the minimum, the MacPerl application 
or tool may crash during connection. Otherwise, the MacPerl application and the tool usually report an "out of memory!" 
or a "Can't connect as user X" error. However, if you get such an out of memory error, it's better to quit the 
corresponding application (and assign more RAM to it). If you try to run another script, you can crash your computer.

=head1 HOW TO GET dtF/SQL 2.01

Please note that dtF/SQL 2.01 is freely available only for non-commercial use. See sLAB's License Agreement 
for details.

Downloading dtF/SQL version 2.01 requires registration. Visit sLAB's web site at http://www.slab.de/us/home/, 
go to the download section and register yourself (your name and email-address are sufficient). Within a few 
minutes, you will get a user name and password via email. Now, visit their web site again, go straight to the 
download section, choose 'Non-public Download', wait for the file list to come and choose

 dtF/SQL 2.01 for MacOS
 	dtFmac-201.sit	Size: 3395 kByte	Date: 09/14/2000 .
	
Then choose "License agreement for non-commercial users", read and agree to the upcoming License Agreement 
to actually download the file.

There are older versions of dtF/SQL available, and some don't require registration. However, this module
was written for version 2.01 and B<will not work with older versions of dtF/SQL>. With the 2.0 release of
the dtF/SQL database engine, its API has been revamped.

Within the downloaded package, you will find the shared library (PPC only) needed for this module, as well as 
the static PPC and 68K libraries, the documentation, a tool for administrating a dtF/SQL database (PPC only), 
the dtF/SQL database server (PPC only), sample source code (in C and C++) and other useful stuff. Please note 
that this module is useless without the dtF/SQL shared library, as you might guess.


=head1 dtF/SQL 2.01 (KNOWN) LIMITATIONS

The current implementation of the dtF/SQL database engine is limited to one connection at a time, as 
documented. But it also has some limitations (bugs?), beyond from what is documented or obvious (see 
the dtF/SQL SPECIFICATION section). The following restrictions were detected while working with 
dtF/SQL. 

* The dtF/SQL database engine could only be used in single-user mode (i.e. locally), because the dtF/SQL 
Database-Server, needed for a network connection, doesn't work as expected (at least on a single Mac, 
running Mac OS 8.6 and Open Transport v2.0.3, acting both as a client and server; I haven't tested it in 
a network).

* There is a limitation (bug?) concerning foreign keys consisting of multiple columns. Basically, a foreign 
key is a column or group of columns within a (dependant) table that references a primary key in some other 
(parent) table. Foreign keys provide a way to enforce the referential integrity of a database. The check for 
referential integrity works fine in dtF/SQL as long as the foreign key consists of a single column: A record 
will *not* be accepted if the foreign key doesn't exist (as primary key) in the parent table; you will 
get an error message. But for multi-column foreign keys dtF/SQL cannot check the referential integrity. A 
record will be accepted even if the foreign key doesn't exist (as primary key) in the parent table. Don't rely 
on this feature.

* The dtF/SQL cascaded delete feature (ON DELETE DELETE or ON DELETE CASCADE action-constraint/trigger), 
which helps to preserve the referential integrity of a database, doesn't work properly. Let's say, table 
A is the parent table with primary key [A.id]. Table B is the dependent table, i.e. contains a foreign key 
[B.id] which is the primary key of table A. The primary key of table B is a multi-column key [B.id, B.id2], 
i.e. the foreign key [B.id] of table B is part of its primary key. Table B was created with the cascaded 
delete action-constraint set for this foreign key [B.id]. If you now delete a record in table A, dtF/SQL will, 
as you expect, delete the corresponding records (where A.id = B.id) in table B too. *But*, if you try to 
insert one of the just deleted records into table B again (same multi-column primary key), you will get a 
referential integrity error, saying "UNIQUE value exists for column 'B.id' ", i.e. dtF/SQL hasn't realized, 
that the primary key is free for use again. This doesn't happen if you delete the corresponding records in 
table B by hand, i.e. with a DELETE statement. Because this cascaded delete behavior is not what you might 
expect, don't rely on this feature.

* dtF/SQL is also a bit weak on documentation. It contains some errors (e.g. wrong cross-references in 
the C/C++/Java Reference manual), but generally it's not that bad that one can't work with it. All in 
all, it doesn't go into deep detail and is very brief on some relevant topics (auto-commit behavior,  
for example). 

There may be other limitations that I haven't detected yet -- comments welcome. 


=head1 API CONSTANTS

There are various constants that are defined in the API.


=head2 MISCELLANEOUS

    DTF_FALSE
    DTF_TRUE
    NULL
    DTFHANDLE_NULL
    DTF_INVALID_COUNT

=head2 DIMENSION CONSTANTS

    DTF_MAX_NAME          #  max length for column and table names (incl. \0)
    DTF_MAX_USERPASS      #  max length of user name or password (incl. \0)

    #  min and max database file size, in KBytes
    DTF_MIN_MAXSIZE       #  ...KB == 2MB
    DTF_MAX_MAXSIZE       #  ...KB == 2GB

    DTF_MAX_FIELDLENGTH   # max non-blob fieldlength

=head2 ERROR CODE CONSTANTS

    DTF_ERR_OK                 DTF_ERR_BUFFER_FULL 
    DTF_ERR_BAD                DTF_ERR_EXISTS
    DTF_ERR_FATAL              DTF_ERR_DOES_NOT_EXIST
    DTF_ERR_OTHER              DTF_ERR_SERVER
    DTF_ERR_BAD_ID             DTF_ERR_CLIENT
    DTF_ERR_LOCK               DTF_ERR_SYNC
    DTF_ERR_NO_SEG             DTF_ERR_NET
    DTF_ERR_NO_PAGE            DTF_ERR_STOPPED
    DTF_ERR_NO_BUFFER          DTF_ERR_PASSWORD
    DTF_ERR_IO                 DTF_ERR_ACCESS
    DTF_ERR_FULL               DTF_ERR_DIV_BY_ZERO
    DTF_ERR_NO_FILE            DTF_ERR_CONVERSION
    DTF_ERR_RANGE              DTF_ERR_RESOURCE
    DTF_ERR_FILE               DTF_ERR_TM_FULL
    DTF_ERR_MEMORY             DTF_ERR_VERSION
    DTF_ERR_INTEGRITY          DTF_ERR_LOG_READY
    DTF_ERR_NO_SCAN            DTF_ERR_SEQUENCE
    DTF_ERR_NO_MORE_RECORDS    DTF_ERR_USER

=head2 RESULT TYPE OF CURSOR

    DTF_RT_SEQUENTIAL
    DTF_RT_RANDOM

=head2 RESULT CLASS OF QUERY

    # see the documentation of the query functions for details
    DTF_RC_OTHER
    DTF_RC_RESULT_AVAILABLE
    DTF_RC_ROWS_AFFECTED

=head2 CONNECTION FLAGS

    DTF_CF_FILENAME
    DTF_CF_NETWORK
    DTF_CF_FSSPEC

=head2 ATTRIBUTE CONSTANTS

Generally, you can use the function DtfAttrQueryInfo() to get the default values of all attributes. 
Use the function DtfHdlQueryAttribute() to get the actual value of an attribute after creating the 
appropriate handle and its dependent handles. For example, you cannot create a connection handle 
without creating an environment handle first (which is the connection handle's dependent handle -- 
got it? :).

Use DtfHdlSetAttribute() to change the value of an attribute. A handle's attributes can only be 
modified when the handle is not in locked state. A handle assumes the locked state by creating 
dependent handles on it. For example, the creation of a connection handle causes the environment 
handle to assume locked state. Additionally, a connection handle assumes locked state when it 
undergoes a transition into connected state (a user connects).


S<  >I<ATTRIBUTE TYPES>

    DTF_ATY_LONG 
    DTF_ATY_STRING 
    DTF_ATY_ENUM

S<  >I<INVALID ATTRIBUTE>

    DTF_AT_NONE

S<  >I<GLOBAL SCOPE ATTRIBUTES>
    
    DTF_AT_CODEPAGE

S<  >I<ENVIRONMENT SCOPE ATTRIBUTES>

    DTF_EAT_MESSAGEFILE    DTF_EAT_VMTYPE
    DTF_EAT_RESULTS        DTF_EAT_VMPATH 
    DTF_EAT_RESULTPAGES    DTF_EAT_VMSLOTS
    DTF_EAT_LOGLEVEL       DTF_EAT_VMFILESLOTS
    DTF_EAT_LOGFILE        DTF_EAT_VMFREEMEM 
    DTF_EAT_XSFILES


S<  >I<CONNECTION SCOPE ATTRIBUTES>

    DTF_CAT_TIMEOUT          DTF_CAT_R4STATE
    DTF_CAT_RESETADAPTER     DTF_CAT_R4PATH
    DTF_CAT_REMOVENETNAME    DTF_CAT_R4BACKUPPATH 
    DTF_CAT_NETSYNCDELAY     DTF_CAT_R4LOGFILESIZE
    DTF_CAT_TRANSACTIONS     DTF_CAT_DBTYPE
    DTF_CAT_CACHEBUFFERS     DTF_CAT_DBCREATOR
    DTF_CAT_PAGEALGO         DTF_CAT_SRVSETUP
    DTF_CAT_R4MODE           DTF_CAT_AUTORECOVER


S<  >I<TRANSACTION SCOPE ATTRIBUTES>    

    DTF_TAT_AUTOCOMMIT
    DTF_TAT_RESULTTYPE

    These two attributes are very important, as they control the auto-commit behavior of the
    database and the kind (sequential, random) of the result set's cursor. The following table 
    shows the available information regarding these attributes:

    --------------------+------------+---------------+---------------+-------------------
    Attribute           | Attr. Type | current Value | default Value | Range
    --------------------+------------+---------------+---------------+-------------------
    DTF_TAT_AUTOCOMMIT  | Enum       |         false |         false | false,true
    DTF_TAT_RESULTTYPE  | Enum       |    sequential |    sequential | sequential,random 
    --------------------+------------+---------------+---------------+-------------------



S<  >I<RESULT SCOPE ATTRIBUTES>

    DTF_RAT_TYPE
    
S<  >I<COLUMN SCOPE ATTRIBUTES>

    DTF_LAT_NAME
    DTF_LAT_TABLENAME
    DTF_LAT_CTYPE
    DTF_LAT_DEFINITION
    DTF_LAT_SIZE
    DTF_LAT_DISPLAYWIDTH
    DTF_LAT_PRECISION
    DTF_LAT_SCALE

    These attributes provide meta information about the result table's columns. This implies,
    that a result table/result handle must exist before you can get at this information.

    Let's assume you have created a table with the SQL statement
         
         "CREATE TABLE foobar (article varchar(30), price decimal(6,2))".

    The following tables show all the attribute informations you could retrieve for these two 
    columns, when they are part of a result set. After creating a column handle (dependent on 
    the result handle) with the function DtfColCreate(), you can use the functions DtfColName(), 
    DtfColTableName(), DtfColCType() in addition to DtfHdlQueryAttribute() and DtfAttrQueryInfo() 
    to retrieve the information. A value of -1 means not applicable. 
  
    column article:
 
    ------------------------+------------+---------------+---------------+----------
    Attribute               | Attr. Type | current Value | default Value | Range
    ------------------------+------------+---------------+---------------+----------
    DTF_LAT_NAME            | String     |       article |               | *
    DTF_LAT_TABLENAME       | String     |        foobar |               | *
    DTF_LAT_CTYPE           | Long       |             9 |             0 | 0-10 +++
    DTF_LAT_DEFINITION      | String     |   varchar(30) |               | *
    DTF_LAT_SIZE (in byte)  | Long       |            31 |             0 | *
    DTF_LAT_DISPLAYWIDTH    | Long       |            30 |             0 | *
    DTF_LAT_PRECISION       | Long       |            30 |             0 | *
    DTF_LAT_SCALE           | Long       |            -1 |             0 | *
    ------------------------+------------+---------------+---------------+----------
    +++ note that the range information for the C type is not correct, should be 0-16
 
    column price:
 
    ------------------------+------------+---------------+---------------+----------
    Attribute               | Attr. Type | current Value | default Value | Range
    ------------------------+------------+---------------+---------------+----------
    DTF_LAT_NAME            | String     |         price |               | *
    DTF_LAT_TABLENAME       | String     |        foobar |               | *
    DTF_LAT_CTYPE           | Long       |            16 |             0 | 0-10 +++
    DTF_LAT_DEFINITION      | String     |  decimal(6,2) |               | *
    DTF_LAT_SIZE (in byte)  | Long       |             8 |             0 | *
    DTF_LAT_DISPLAYWIDTH    | Long       |             8 |             0 | *
    DTF_LAT_PRECISION       | Long       |             6 |             0 | *
    DTF_LAT_SCALE           | Long       |             2 |             0 | *
    ------------------------+------------+---------------+---------------+----------
    +++ note that the range information for the C type is not correct, should be 0-16


=head2 C DATA TYPE IDs


    DTF_CT_DEFAULT    DTF_CT_CSTRING
    DTF_CT_CHAR       DTF_CT_SQLSTRING
    DTF_CT_UCHAR      DTF_CT_BLOB
    DTF_CT_SHORT      DTF_CT_DATE
    DTF_CT_USHORT     DTF_CT_TIME 
    DTF_CT_LONG       DTF_CT_TIMESTAMP
    DTF_CT_ULONG      DTF_CT_DECIMAL
    DTF_CT_BOOL       DTF_CT_COUNT
    DTF_CT_DOUBLE



=head2 dtF/SQL DATA TYPE IDs

    DTF_DT_NULL        DTF_DT_SHORTSTRING
    DTF_DT_BYTE        DTF_DT_BIT
    DTF_DT_WORD        DTF_DT_DATE
    DTF_DT_LONGWORD    DTF_DT_TIME
    DTF_DT_CHAR        DTF_DT_TIMESTAMP
    DTF_DT_SHORT       DTF_DT_COUNT
    DTF_DT_LONG        DTF_DT_DECIMAL
    DTF_DT_REAL


=head1 ADDITIONAL MODULE CONSTANTS

The following constants are defined in this module.

    not_NULL
    AUTO_COMMIT_ON
    AUTO_COMMIT_OFF
    

=head1 API FUNCTIONS

Instead of listing all API functions in alphabetical order (as in the reference manual), they are grouped into
categories and ordered in a more or less chronological and/or task oriented way. In the following, 
a function prototype and a brief description of the arguments will be given. Only differences to the original 
C API will be explained in greater detail. For the rest, the reader is referred to the dtF/SQL C/C++/Java 
Reference manual (PDF format). It is highly recommended that you look at the samples that come with this module 
(especially C<browser.pl>) for a better understanding of the API functions. Please note, that not all of the
C API functions are supported (especially those handling blob -- binary large object -- data). Only the functions 
listed here can be called from Perl.

Most of the functions return the constant DTF_ERR_OK on success, which is 0. Be aware of this when you use the
error code in a conditional statement.

B<Important note:> All arguments marked as 'in & out' or 'output' must be lvalues, i.e. variables you can assign 
a scalar. B<Don't> pass values to these arguments. As you might guess, 'in & out' or 'output' means Call by Reference,
while 'input' means Call by Value.



=head2 CONNECT TO A DATABASE

=over 4

=item B<$errcode = DtfEnvCreate ($henv);> 

 # create an environment handle (STEP 1)

 Arguments:
   output: $henv  an environment handle
   


=item B<$errcode = DtfConCreate ($henv, $connectSpec, $flags, $hcon);> 

 # create a connection handle (STEP 2)

 Arguments:
   input:  $henv         a valid environment handle
           $connectSpec  data source name
           $flags        either DTF_CF_FILENAME or DTF_CF_NETWORK or DTF_CF_FSSPEC 
   
   output: $hcon  a connection handle



=item B<$henv = DtfConQueryEnvHandle ($hcon);> 

 # return the connection handle's dependent environment handle

 Arguments:
   input:  $hcon  a valid connection handle



=item B<$errcode = DtfConQueryStatus ($hcon, $connected, $dbExists, $dbConsistent);> 

 # query connection status

 Arguments:
   input:    $hcon          a valid connection handle
   in & out: $connected     is the connection handle in connected state? (true or false)
                            *MAY BE NULL* on input; If you want to get back a valid value  
                            (1 for true or 0 for false in this case), be sure to pass a scalar 
                            variable that is initialised to *not* NULL to this argument; you 
                            may want to use the constant not_NULL for this purpose. If you are 
                            not interested in the output value of this argument, pass NULL or 
                            0 to it (no lvalue required).
             
             $dbExists      does the database exist? (true or false)
                            *MAY BE NULL* on input; same warning as above

             $dbConsistent  is the database in consistent state? (true or false)
                            *MAY BE NULL* on input; same warning as above



=item B<$errcode = DtfConRecoverDatabase ($hcon);> 

 # recover a database

 Arguments:
   input: $hcon  a valid connection handle



=item B<$errcode = DtfConConnect ($hcon, $username, $password); >

 # connect as user to a database (STEP 3)

 Arguments:
   input:  $hcon      a valid connection handle
           $username  a registered user name  
           $password  ... and his password



=item B<$errcode = DtfTraCreate ($hcon, $htra);> 

 # create a transaction handle (STEP 4)

 Arguments:
   input:   $hcon  a valid connection handle
   output:  $htra  a transaction handle
   


=item B<$hcon = DtfTraQueryConHandle ($htra);> 

 # return the transaction handle's dependent connection handle

 Arguments:
   input:   $htra  a valid transaction handle


S< >

=back


=head2 QUERYING THE DATABASE

=over 4

=item B<$errcode = DtfTraExecute ($htra, $sql, $reqClass, $nrAffectedRecords, $hres);> 

 # execute an arbitrary SQL statement

 Arguments:
   input:  $htra  a valid transaction handle
           $sql   a SQL statement to execute
                  *MAY BE NULL*. If you pass 0 (or the constant NULL) to $sql, this has a 
                  special meaning as discussed in the dtf/SQL C/C++/Java Reference manual.
   
   output: $reqClass           class of request: either DTF_RC_ROWS_AFFECTED or 
                               DTF_RC_RESULT_AVAILABLE or DTF_RC_OTHER
           $nrAffectedRecords  the number of affected records
           $hres               a result handle



=item B<$errcode = DtfTraExecuteQuery ($htra, $sql, $restype, $hres);> 

 # execute a SQL statement which yields a result set

 Arguments:
   input:  $htra     a valid transaction handle
           $sql      a SQL statement to execute      
                     *MAY BE NULL*. If you pass 0 (or the constant NULL) to $sql, this has a 
                     special meaning as discussed in the dtf/SQL C/C++/Java Reference manual.
           $restype  result type: either DTF_RT_SEQUENTIAL or DTF_RT_RANDOM
   
   output: $hres  a result handle
   


=item B<$errcode = DtfTraExecuteUpdate ($htra, $sql, $nrAffectedRecords); >

 # execute a modifying SQL statement which does not yield a result set

 Arguments:
   input:  $htra  a valid transaction handle
           $sql   a SQL statement to execute
                  *MAY BE NULL*. If you pass 0 (or the constant NULL) to $sql, this has a 
                  special meaning as discussed in the dtf/SQL C/C++/Java Reference manual.
   
   output: $nrAffectedRecords  the number of affected records

S< >

=back

=head2 RESULT HANDLING

=over 4

=item B<$rowcount = DtfResRowCount ($hres);> 

 # get the number of rows of the result table

 Arguments:
   input:  $hres  a valid result handle




=item B<$columncount = DtfResColumnCount ($hres);> 

 # get the number of columns of the result table

 Arguments:
   input:  $hres  a valid result handle



=item B<$errcode = DtfColCreate ($hres, $colIndex, $hcol);> 
 
 # create a column handle from the current result table

 Arguments:
   input:   $hres      a valid result handle
            $colIndex  identifies the result set's column between 0 and columnCount - 1
   
   output:  $hcol  a column handle



=item B<$tablename = DtfColTableName ($hcol);> 

 # get the table name this column belongs to

 Arguments:
   input: $hcol  a valid column handle



=item B<$columnname = DtfColName ($hcol);> 

 # get the column name

 Arguments:
   input: $hcol  a valid column handle



=item B<$datatype_code = DtfColCType ($hcol); >
  
 # get the column's C data type code (see below)

 Arguments:
   input: $hcol  a valid column handle



=item B<$errcode = DtfColDestroy ($hcol);> 

 # destroy the column handle

 Arguments:
   input: $hcol  a valid column handle



=item B<$errcode = DtfResMoveToFirstRow ($hres);> 

 # move to the first row of a result table with a sequential cursor
 # (the result table must be of type DTF_RT_SEQUENTIAL)

 Arguments: 
   input:  $hres  a valid result handle



=item B<$errcode = DtfMoveToNextRow ($hres);> 

 # move to the next row of a result table with a sequential cursor
 # (the result table must be of type DTF_RT_SEQUENTIAL)

 Arguments: 
   input:  $hres  a valid result handle



=item B<$errcode = DtfResMoveToRow ($hres, $rowIndex);> 

 # moves a result set's cursor to an absolute position
 # (the result table must be of type DTF_RT_RANDOM)

 Arguments: 
   input:  $hres      a valid result handle
           $rowIndex  is the 0-based index of the row to move the cursor to



=item B<$errcode = DtfResQueryFieldInfo ($hres, $colIndex, $fieldSize, $isNull);> 

 # retrieve information about a result set's field

 Arguments: 
   input:  $hres       a valid result handle
           $colIndex   is the 0-based index of the field to retrieve information about
           
   output: $fieldSize  field size in byte
           $isNull     true if the field's value is NULL, false otherwise 



=item B<$errcode = DtfResGetField ($hres, $colIndex, $retrieve_as_Type, $fieldVal, $isNull, $typeHint);> 

 # get the data of this field

 Arguments: 
   input:   $hres              a valid result handle
            $colIndex          is the column index of the field to retrieve (0-based).
            $retrieve_as_Type  either DTF_CT_DEFAULT (= 0) or DTF_CT_CSTRING (= 9) or DTF_CT_SQLSTRING (= 10)
            $typeHint          if $retrieve_as_Type is DTF_CT_DEFAULT, then you *must* specify 
                               the datatype of the data field
   
   output:  $fieldVal  the field's value
            $isNull    true if the field's value is NULL, false otherwise 


Note (1): Due to the differences between the Perl and the C language, the number of parameters  
is slightly different from the C version, i.e. the $typeHint parameter has been added.
 
Note (2): The retrieval as DTF_CT_BLOB type is *not* supported. This Perl interface doesn't handle 
the binary large objects data (blob) type.

Note (3): If you specify the DTF_CT_DEFAULT as the retrieval type, this means that the field value 
will be retrieved as stored in the database without converting it to a string. In this case, you 
have to specify a type hint, i.e. the C datatype of the data field. The type can be determined with
the DtfColCType (...) function (see above) and can be one of the following (integer) constants:

     - DTF_CT_CHAR           #  1   //  signed byte (char)
     - DTF_CT_UCHAR          #  2   //  unsigned byte (char)
     - DTF_CT_SHORT          #  3   //  short
     - DTF_CT_USHORT         #  4   //  unsigned short
     - DTF_CT_LONG           #  5   //  long
     - DTF_CT_ULONG          #  6   //  unsigned long
     - DTF_CT_DOUBLE         #  8   //  double
     - DTF_CT_CSTRING        #  9   //  character string
     - DTF_CT_DATE           # 13   //  date type (like string), format: 'yyyy/mm/dd' or 'yyyy-mm-dd' 
     - DTF_CT_TIME           # 14   //  time type (like string), 24 hour format 'hh:mm:ss' or with 
                                    //  second fractions 'hh:mm:ss.fff'
     - DTF_CT_TIMESTAMP      # 15   //  timestamp type (like string), format: YYYY-MM-DD hh:mm:ss[.fff]
     - DTF_CT_DECIMAL        # 16   //  decimal type

In Perl, these data types -- except the decimal type -- are all scalar types. But internally, Perl 
distinguishes between integer (IV), double (NV) and string (PV) scalar types. Thus, there is indeed a 
difference in retrieving data with the retrieval type set to DTF_CT_CSTRING or set to DTF_CT_DEFAULT.

However, for calculations with retrieved data, it makes no great difference (except for the decimal type) if 
you retrieve a field value as string or as stored in the database with attention to its actual datatype: The 
scalars will contain either numbers or strings. In general, conversion from one form to another is transparent, 
i.e. happens automatically in Perl. This should be suitable even for the decimal datatype when retrieved as 
string, because it is converted to a scalar holding a floating point number in arithmetical operations (although 
the accuracy may suffer).
  
Note (4): If you retrieve data of type decimal, you will get back a *decimal object* in $fieldVal-- see
the section DECIMAL NUMBERS below. This decimal object will be automatically created for you, 
i.e. there is no need to create a decimal object in before and pass it to the function. Hint:
When you retrieve data in a loop, use the ref() function
       
       if ref($fieldVal) { ... } else { ... } 
  
to distinguish between scalars and objects.



=item B<$errcode = DtfResDestroy ($hres);>

 # destroy the result handle

 Arguments: 
   in & out:  $hres  will be set to 0 (NULL) on output
   
S< >

=back


=head2 DISCONNECTING FROM A DATABASE

=over 4

=item B<$errcode = DtfTraDestroy ($htra);> 

 # destroy a transaction handle

 Arguments: 
   in & out:  $htra  will be set to 0 (NULL) on output



=item B<$errcode = DtfConDisconnect ($hcon);> 

 # disconnect from a connection handle

 Arguments: 
   input:  $hcon  a valid connection handle 



=item B<$errcode = DtfConDestroy ($hcon);> 

 # destroy a connection handle

 Arguments: 
   in & out:  $hcon  will be set to 0 (NULL) on output
   


=item B<$errcode = DtfEnvDestroy ($henv);> 

 # destroy an environment handle

 Arguments: 
   in & out:  $henv will be set to 0 (NULL) on output
   
S< >

=back


=head2 ERROR HANDLING

=over 4

=item B<$errcode = DtfHdlGetError ($hdl, $code, $msg, $group, $errpos);> 

 # get error code, message, group, position

 Arguments:
   input:   $hdl  a valid handle of any kind
   
   output:  $code    error code
            $msg     error message
            $group   error group
            $errpos  error position

 Note: Due to the differences between the Perl and the C language, the number of parameters  
 is slightly different from the C version, i.e. the msgbufSize and groupbufSize parameters 
 have been removed and will be handled internally.

S< >
 
=back



=head2 CREATE/DELETE A DATABASE

=over 4

=item B<$errcode = DtfConCreateDatabase ($hcon, $admUserName, $admPassWord, $ratioIndRel, $maxSize, $indexSize, $relationSize); >

 # create a database

 Arguments:
   input:   $hcon          a valid connection handle
            $admUserName   the default administrator's user name
            $admPassWord   ... and his default password
            $ratioIndRel   ratioIndRel defines the ratio (in percent) between the space reserved 
                           for index data and the space reserved for relation data. Possible
                           values range from 10 to 60, and 0 for an internally defined default 
                           value, something around 25 percent.
            $maxSize       defines the database file’s maximum size, in KB

   output:  $indexSize     the available space for index data, in KB
            $relationSize  the available space for relation data, in KB



=item B<DtfConDeleteDatabase ($hcon);>

 # delete a database

 Arguments: 
   input:  $hcon  a valid connection handle 

S< >

=back


=head2 EXPANDING/SHRINKING A DATABASE: ADD AND REMOVE DATAFILES

=over 4

=item B<$datafile_count = DtfConDataLocationCount ($hcon);> 

 # get the number of the database's data files (aka data locations)

 Arguments:
   input:   $hcon  a valid connection handle

  

=item B<$datafile_name = DtfConDataLocation ($hcon, $fileIndex, $maxSize, $curSize);> 
 
 # get filename, max. size, current size for a data file (aka data location)

 Arguments:
   input:   $hcon       a valid connection handle
            $fileIndex  a data file's internal index: 0 .. ($datafile_count - 1)
   
   output:  $maxSize  max. size of data file in KB
            $curSize  current size of data file in KB


      
=item B<$errcode = DtfConAddDataLocation ($hcon, $fileName, $maxSize, $fileIndex);> 

 # add a new data file (aka data location)

 Arguments:
   input:   $hcon       a valid connection handle
            $fileName   data files filename
            $maxSize    max. size of data file in KB
   output:  $fileIndex  data file's internal index



=item B<$errcode = DtfConRemoveDataLocation ($hcon, $fileIndex);> 

 # remove one of the data files (aka data locations)

 Arguments:
   input:   $hcon       a valid connection handle
            $fileIndex  data file's internal index

            
           
=item B<$errcode = DtfConChangeDataLocation ($hcon, $fileIndex, $newFileName);> ***DO NOT USE***  

 # move a data file (aka data location) to a new location 

 Arguments:
   input:   $hcon         a valid connection handle
            $fileIndex    data file's internal index
            $newFileName  filename specifies new location
 
B<Important note>: This function simply B<doesn't work>. It does nothing and always returns DTF_ERR_BAD (= 1). Because 
this function is the only way to move a data file (aka data location) to a new location, be careful where you place your 
additional data files.

S< >
   
=back


=head2 GET/SET DATABASE ATTRIBUTS

=over 4

=item B<$errcode = DtfHdlQueryAttribute ($hdl, $attr, $value);> 

 # get the value of an handle's attribut

 Arguments:
   input:   $hdl    a valid handle of any kind
            $attr   an attribute (use one of the attribute constants)
   output:  $value  the attribute's value

Note: Due to the differences between the Perl and the C language, the number of parameters  
is slightly different from the C version, i.e. the valueSize parameter has been removed 
and will be handled internally
 


=item B<$errcode = DtfHdlSetAttribute ($hdl, $attr, $value);> 

 # set the value of an handle's attribut

 Arguments:
   input:   $hdl    a valid handle of any kind
            $attr   an attribute (use one of the attribute constants)
            $value  the attribute's new value
   

 
=item B<$errcode = DtfAttrQueryInfo ($attr, $type, $defaultVal, $rangeSpec);> 

 # for a given attribut, retrieve it's type, default value, and value range

 Arguments:
   input:     $attr        an attribut constant

   in & out:  $type        the datatype of the attribut, either DTF_ATY_LONG (= 0) or DTF_ATY_STRING(= 1) or 
                           DTF_ATY_ENUM (= 2) (on output)
                           *MAY BE NULL* on input; If you want to get back a valid value, be sure 
                           to pass a scalar variable that is initialised to *not* NULL (not 0) to this 
                           argument; you may want to use the constant not_NULL (= 1) for this purpose. 
                           If you are not interested in the output value of this argument, pass NULL 
                           or 0 to it (no lvalue required).
              
              $defaultVal  the default value of the attribut
                           *MAY BE NULL* on input; same warning as above

              $rangeSpec   a string describing the attribute's value range   
                           *MAY BE NULL* on input; same warning as above

                           
Note: Due to the differences between the Perl and the C language, the number of parameters  
is slightly different from the C version, i.e. the defValueSize parameter has been removed 
and will be handled internally


=item B<$errcode = DtfHdlEnumAttribute ($hdl, $index, $attribut);> 

 # determine a handle's attribute by its index

 Arguments:
   input:   $hdl        a valid handle of any kind
            $index      the attribute’s index (0-based)
   output:  $attribute  an attribute constant

S< >

=back


=head2 GET/SET USERDATA

=over 4

=item B<$errcode = DtfHdlSetUserData ($hdl, $userData);> 

 # set a handle's private user data

 Arguments:
   input:   $hdl       a valid handle of any kind
            $userData  a string containing the private user data to store



=item B<$errcode = DtfHdlQueryUserData ($hdl, $userData);> 

 # get a handle's private user data

 Arguments:
   input:   $hdl  a valid handle of any kind
   output:  $userData  a string containing the private user data

S< > 

=back


=head1 ADDITIONAL MODULE FUNCTIONS

You may want to use one of the additional (Perl-ish) module functions (highly recommended). 

=over 4

=item  B<($henv, $hcon, $htra, $errcode, $errstr) = dtf_connect ($dsn, $username, $password);>

 # connect to a database

 dtf_connect handles all the needed steps to connect to a existing database, including recovery in 
 single-user mode (if necessary). On success ($errcode = DTF_ERR_OK = 0), it returns a valid environment, 
 connection, and transaction handle. On error, it returns an error code as specified in the API 
 CONSTANTS section (see above) and an error message explaining the error.  

 Arguments:
   input: $dsn       DSN = data source name; for the single-user version, $dsn should be the database's 
                     partial or fully qualified path (for example "MacHD:path:to:DB:TESTDB.dtf"), for 
                     the multi-user verion it should be a server specification (for example "tcp:host/port")
          $username  user name
          $password  password


=item  B<($henv, $hcon, $htra, $errcode, $errstr) = dtf_connectpp ($dsn, $username, $password);>

 # same as above, but written in pure Perl (pp)
  

=item B<($errcode, $errstr) = dtf_disconnect ($henv, $hcon, $htra);>

 # disconnect from a database

 dtf_disconnect handles all the needed steps to disconnect from a database. On success, the error code is
 set to DTF_ERR_OK (= 0). On error, it returns an error code as specified in the API CONSTANTS section 
 (see above) and an error message explaining the error.
 
 Arguments:
   input: $henv, $hcon, $htra  # environment, connection and transaction handle
   
   
=item B<($errcode, $errstr) = dtf_disconnectpp ($henv, $hcon, $htra);>

 # same as above, but written in pure Perl (pp)

S< >  
  
=back



=head1 DECIMAL NUMBERS
 
The dtF/SQL API declares a special data type for fixed point numbers, DTFDECIMAL. Fixed point numbers 
have a fixed number of decimals ahead of the decimal point, and an explicitly defined number of  
fraction decimals. As mentioned, handling of these fixed point numbers (the term decimals will be 
used as a synonym), i.e. creation, arithmetic operations, converting etc., is a bit different from the 
original C API. In Perl, operations with decimals are done in an object-oriented way, i.e. the decimal 
is the object and the operation is the method. 

The total number of decimal digits must not exceed 16. In dtF/SQL, a fixed point number must contain at 
least one digit ahead the decimal point, but no digits are required after the decimal point. Fixed point 
numbers may have an optional sign, i.e. they can be either positive or negative numbers. Due to this 
constraints, the greatest possible unsigned number is 9999999999999999 (must be declared as string 
'9999999999999999.'), while the smallest unsigned number not equal 0 is 0.000000000000001. It is left as
an exercise to the reader to figure out what the smallest/greatest signed number would be :).

When you use the decimal data type in a CREATE TABLE statement, you will use the C<decimal(precision, scale)>
notation. Precision denotes the total number of decimal digits and must not exceed 16. The second parameter 
scale denotes the number of digits after the decimal point. The use of 'decimal' is equivalent to 'decimal(1,0)'.
According to the above example, the greatest possible number would be defined as 'decimal(16,0)', while the 
smallest number would be defined as 'decimal(16,15)'.

Sadly enough, dtF/SQL's implementation of decimals is sometimes a bit odd, to be friendly. For example, no error 
will be returned if an overflow regarding the precision/scale occurs in a arithmetical operation, I haven't 
figured out what the C<is_valid> method does (seems to return 1 = OK all the time), the C<equal> method doesn't 
work as one should expect, handling of arithmetic operations with regard to a decimal's scale is error prone if 
the user doesn't take care and the C<set_scale> method doesn't return an error if you set the scale to a value out 
of the 0 .. 15 range. Let me give some examples (see also the C<bad_decimal.pl> script in the samples folder):

 # create objects
   $dec1 = Mac::DtfSQL->new_decimal; 
   $dec2 = Mac::DtfSQL->new_decimal; 

 # equal
   $dec1->from_string('4000');
   $dec2->from_string('4000.0');
   if ($dec1->equal($dec2)) {...} # 4000 != 4000.0, because the scales don't match (autsch) 
 
 # multiplication 
 
 # Note: The scale for an arithmetical operation is determined by the object for which 
 #       the method is called, 0 in the following example
 
   $dec1->from_long(660000);   # 660,000, scale = 0
   $dec2->from_string('0.75'); # 0.75, scale = 2
 
   # wrong
   $dec1->mul($dec2); # == 660,000 and should be 495,000 (autsch) 
                      # internally, 0.75 seems to be rounded to 1 (scale 0), 
                      # *BUT* no error is returned (and this is the crux)
 
   # right
   $scale1 = $dec1->get_scale;
   $scale2 = $dec2->get_scale;
   if ( $scale1 > $scale2 ) {
       $dec2->set_scale( $scale1 );
   } else {
       $dec1->set_scale( $scale2 );
   }
   $dec1->mul($dec2); # == 495,000.00 (ok)

  
 # addition precision/scale overflow 
 
 # Note: The scale for an arithmetical operation is determined by the object for which 
 #       the method is called, 15 in the following example
 
   $dec1->from_string('0.000000000000001'); # decimal (16,15)
   $dec2->from_string('100.50'); # decimal (5,2)
 
   $dec1->add($dec2); # result == 0.500000000000001 and should be 100.500000000000001
                      # precision/scale overflow, because a decimal (18,15) would be needed,
                      # *BUT* no error is returned (and this is the crux)
                      # Indeed, if you convert the decimal to a double value, you will
                      # get 100.5 as a result, i.e. there is no value overflow internally
 
 # No error is returned if you set the scale to a value out of the 0 .. 15 range   
   
   $dec1->set_scale(16) || die "Scale out of range"; # doesn't die


Because of all these flaws, be careful in any operation where the scales of operands don't match. However, for 
calculations with fixed scales (e.g. for prices -- some databases have a special data type MONEY for 
this), the decimal data type should be sufficient. Be careful with value overflows, though.

  
S< >


=head2 DECIMAL CLASS AND OBJECT METHODS


=over 4

=item B<new_decimal> 
 
First, you have to create a new decimal object by calling the new_decimal method. The value of this decimal will be 
initialized to 0. You assign a value by calling one of the methods C<from_string>, C<from_long> or C<assign>.
The returned object reference will be 0 on failure.
 
 
  $dec = Mac::DtfSQL->new_decimal;
  
  $dec->from_string('5500.40');
  $dec->from_long(150000);  
  $dec->assign($dec2);
  
   
B<Important note:> If you call C<DtfResGetField (...)> with the $retrieve_as_Type argument set to DTF_CT_DEFAULT 
(= 0) and the field's actual C data type is decimal (= 16), then the decimal object will be automatically created 
for you, i.e. you do not need to create a decimal in before and pass it to the function's $fieldVal argument.


=item B<from_string> 

This method sets a decimal's value to the value represented by a string. The decimal object must already exist. 
Should return 1 on success, 0 on failure. The string has to represent a valid decimal according to the rules 
mentioned above.

 $dec->from_string('5500.40');

=item B<from_long>

This method sets a decimal's value to the value of a (4 byte signed) long integer. The decimal object must already 
exist. Should return 1 on success, 0 on failure. The value specified has to be a valid long integer, otherwise Perl 
will convert this value to an integer (e.g. 150.75 becomes 150) before passing it to the method. See C<perldata.pod> 
and the C<int> function (C<perlfunc.pod>) for details.


 $dec->from_long(150000);


=item B<assign>

This method assigns the value of the decimal object argument to the decimal object it was called for. The decimal 
object must already exist. Returns 1 on success, result is undefined on failure.

  $dec->assign($dec2); # $dec = $dec2;


=item B<as_string>

This method converts a decimal into a character string. Returns the string representing a decimal on success or 
the empty string '' on failure.

 $decStr = $dec->as_string;
 print "value = " , $dec->as_string , "\n";

=item B<to_double>

This method converts a decimal into a double precision value. The return value is the double precision 
representation of the decimal value.

 $doubleVal = $dec->to_double;

  
=item B<is_valid>

This method tests whether a decimal contains a valid value. This function should return 1 if the operand contains 
a valid decimal, 0 otherwise.

 if ($dec->is_valid) { ... }


=item B<get_scale> 

This method gets the scale of a decimal object. The return value is the operand's scale, i.e. the number 
of decimal places to the right of the decimal point.

 $scale = $dec->get_scale; 
 
 
=item B<set_scale> 

This method sets the scale of a decimal object to $scale, i.e. the number of decimal places to the right 
of the decimal point. $scale must be a value between 0 and 15. Should return 1 on success, 0 on failure.

 $dec->set_scale($scale);


=item B<abs> 

This method sets a decimal object's value to its absolute value. Should return 1 on success, 0 on failure.

 $dec->abs;


=item B<add>

This method adds two decimal values, i.e. the value of the decimal object argument is added to the value of the
decimal object for which the method is called. Should return 1 on success, 0 on failure. The scale for an 
arithmetical operation is determined by the object for which the method is called.

 $dec->add($dec2); # $dec = $dec + $dec2
  

=item B<sub>

This method subtracts two decimal values, i.e. the value of the decimal object argument is subtracted from
the value of the decimal object for which the method is called. Should return 1 on success, 0 on failure. The scale 
for an arithmetical operation is determined by the object for which the method is called.

 $dec->sub($dec2); # $dec = $dec - $dec2
  

=item B<mul>

This method multiplies two decimal values, i.e. the value of the decimal object argument is multiplied with
the value of the decimal object for which the method is called. Should return 1 on success, 0 on failure. The scale 
for an arithmetical operation is determined by the object for which the method is called.

 $dec->mul($dec2); # $dec = $dec * $dec2
  

=item B<div>

This method divides two decimal values, i.e. the value of decimal object for which the method is called is 
divided by the value of the decimal object argument. Should return 1 on success, 0 on failure. The scale for an arithmetical 
operation is determined by the object for which the method is called.  

 $dec->div($dec2); # $dec = $dec / $dec2

=item B<equal>

This method tests if the values of two decimal objects are equal. The return value is set to 1 if both values 
are equal, otherwise it is set to 0.

 if ( $dec->equal($dec2) ) {...}; # $dec == $dec2 ?
  
  

=item B<greater>

This method tests if the value of the object for which the method is called is greater than the value of the decimal 
objects argument. The return value is set to 1 if is greater is true, otherwise it is set to 0.
  
 if ( $dec->greater($dec2) ) {...}; # $dec > $dec2 ?
  


=item B<greater_equal>

This method tests if the value of the object for which the method is called is greater or equal than the value of 
the decimal objects argument. The return value is set to 1 if is greater or equal is true, otherwise it is set to 0.
    
 if ( $dec->greater_equal($dec2) ) {...}; # $dec >= $dec2 ?
 


=item B<less>

This method tests if the value of the object for which the method is called is less than the value of the decimal 
objects argument. The return value is set to 1 if is less than is true, otherwise it is set to 0.
   
 if ( $dec->less($dec2) ) {...}; # $dec < $dec2 ?
 


=item B<less_equal>

This method tests if the value of the object for which the method is called is greater or equal than the value of 
the decimal objects argument. The return value is set to 1 if is less than or equal is true, otherwise it is set 
to 0.
    
 if ( $dec->less_equal($dec2) ) {...}; # $dec <= $dec2 ?

S< >  

=back


=head1 ACKNOWLEDGMENT

I'd like to thank the folks at sLAB Banzhaf & Soltau oHG (http://www.slab.de/), Boeblingen, Germany, 
for making dtF/SQL freely available for non-commercial use. The editors note, quoted from the MacTech 
article mentioned in the REFERENCES section, says it all:

=over 0

 "sLab has made an astonishing offer to the programming community at large - a free, 
 high end SQL relational database for non-commercial use."
 
=back



=head1 REFERENCES

=over 0

=item The dtf/SQL Version 2.01 Documentation (in PDF format):

 Introduction.pdf
 C/C++/Java Reference.pdf
 Programmer's manual.pdf
 SQL Reference.pdf
 
 
=item MacTech article on dtF/SQL:

 "dtF/SQL -- The Little Engine That Could" by William A. Gilbert, 
 MacTech No. 4, Vol. 14 (April 1998)
 
 http://www.mactech.com/articles/mactech/Vol.14/14.04/dtF-SQL/index.html

 
 
=item The Perl XS language is covered in:

 perlguts.pod
 perlapi.pod
 perlxs.pod
 perlxstut.pod
 
 XS Cookbooks by Dean Roehrich    http://www.perl.com/CPAN-local/authors/Dean_Roehrich/

S< >I<(This module uses Dean Roehrich's "perlobject.map" typemap. Credits to Dean Roehrich)


=item Macintosh specific coverage of building a Perl extension:

 Macintosh Perl XS Tutorial 
 
 http://macperl.com/depts/Tutorials/XS/Mac_XS.sea.hqx

S< >I<(Credits to Arved Sandstrom and Alan Fry)>

 An updated version (v1.1) of the tutorial can be found on my website at

 http://usemacperl.esmartweb.com/index.html
 
=back

=head1 AUTHOR AND COPYRIGHT

=over 0

Thomas Wegner    t_wegner@gmx.net

=back
 
Copyright (c) 2000-2002 Thomas Wegner. All rights reserved. This program is
free software. You may redistribute it and/or modify it under the terms
of the Artistic License, distributed with Perl.


=cut
