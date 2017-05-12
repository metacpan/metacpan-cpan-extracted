#! perl -w

# 
# createSampleDB.pl -- This script creates the test database 'SampleDB.dtf' in the current folder;
#                      user 'dtfadm', password 'dtfadm'.
#					   Four user tables will be created and filled with some data for playing around.
#
# Author: Thomas Wegner 
# Date: 2001-Feb-18
#


	use strict;
  	use Mac::DtfSQL qw(:all);

  	$| = 1; # no line buffering
  
  	my @statements = (
	"CREATE TABLE clients (id INTEGER PRIMARY KEY, firstName VARCHAR(255), lastName VARCHAR(255), street VARCHAR(255), city VARCHAR(255))",
    "CREATE TABLE articles (id INTEGER PRIMARY KEY, name VARCHAR(255), package VARCHAR(255), price DECIMAL(6,2))",
  	"CREATE TABLE torder (orderid INTEGER, clientid INTEGER, orderdate date, paid byte, PRIMARY KEY (orderid), FOREIGN KEY (clientid) REFERENCES clients (id))",
	"CREATE TABLE ordered_articles (orderid INTEGER, articleid INTEGER,  amount INTEGER, PRIMARY KEY (orderid, articleid), FOREIGN KEY (orderid) REFERENCES torder (orderid),  FOREIGN KEY (articleid) REFERENCES articles (id))",
	
	"COMMIT"
	);
	
    my @lastname = (
	"White","Karsen","Smith","Ringer","May","King","Fuller",
    "Miller","Ott","Sommer","Schneider","Steel","Peterson","Heiniger","Clancy"
	);
    
	my @firstname = (
	"Mary","James","Anne","George","Sylvia","Robert","Thomas","Linda","Claudia",
    "Janet","Michael","Andrew","Bill","Susan","Laura","Bob","Julia","John"
	);
	
    my @street = (
	"Upland Pl. ","College Road ","20th Ave. ","Seventh Av. ", "Silicon Alley ", "Baker Street "
	);
	
    my @city = (
	"New York","Los Angeles","Boston","San Diego","Seattle",
    "San Francisco","London","Berlin","Paris","Chicago","Palo Alto","Cupertino"
	);
	
	my @articles = (	 
	"'Chai','10 boxes x 20 bags',18.00",
	"'Chang','24 - 12 oz bottles',19.00",
	"'Aniseed Syrup','12 - 550 ml bottles',10.00",
	"'Chef Anton''s Cajun Seasoning', '48 - 6 oz jars',22.00",
	"'Chef Anton''s Gumbo Mix','36 boxes',21.35",
	"'Grandma''s Boysenberry Spread','12 - 8 oz jars',25.00",
	"'Uncle Bob''s Organic Dried Pears','12 - 1 lb pkgs.',30.00",
	"'Northwoods Cranberry Sauce','12 - 12 oz jars',40.00",
	"'Mishi Kobe Niku','18 - 500 g pkgs.',97.00",
	"'Ikura','12 - 200 ml jars',31.00",
	"'Queso Cabrales','1 kg pkg.',21.00",
	"'Queso Manchego La Pastora','10 - 500 g pkgs.',38.00",
	"'Konbu','2 kg box',6.00",
	"'Tofu','40 - 100 g pkgs.',23.25",
	"'Genen Shouyu','24 - 250 ml bottles',15.50",
	"'Pavlova','32 - 500 g boxes',17.45",
	"'Alice Mutton','20 - 1 kg tins',39.00",
	"'Carnarvon Tigers','16 kg pkg.',62.50",
	"'Teatime Chocolate Biscuits','10 boxes x 12 pieces',9.20",
	"'Sir Rodney''s Marmalade','30 gift boxes',81.00",
	"'Sir Rodney''s Scones','24 pkgs. x 4 pieces',10.00",
	"'Gustaf''s Knäckebrot','24 - 500 g pkgs.',21.00",
	"'Danish Tunnbröd','12 - 250 g pkgs.',9.00",
	"'Guaran Fantastica','12 - 355 ml cans',4.50",
	"'Nutella Nuß-Nougat-Creme','20 - 450 g glasses',14.00",
	"'Haribo Gummibärchen','100 - 250 g bags',31.23",
	"'Schoggi Schokolade','100 - 100 g pieces',43.90",
	"'Rössle Sauerkraut','25 - 825 g cans',45.60",
	"'Thüringer Rostbratwurst','50 bags x 30 sausgs.',123.79",
	"'Bremer Matjeshering','10 - 200 g glasses',25.89",
	"'Gorgonzola Telino','12 - 100 g pkgs',12.50",
	"'Mascarpone Fabioli','24 - 200 g pkgs.',32.00",
	"'Geitost','500 g',2.50",
	"'Sasquatch Ale','24 - 12 oz bottles',14.00",
	"'Steeleye Stout','24 - 12 oz bottles',18.00",
	"'Beck''s Bier','10 - 6 pack, 0.33l bottles',39.00",
	"'Gravad lax','12 - 500 g pkgs.',26.00",
	"'CÙte de Blaye','12 - 75 cl bottles',263.50",
	"'Chartreuse verte','750 cc per bottle',18.00",
	"'Boston Crab Meat','24 - 4 oz tins',18.40"
	);
	

	my @order_statements = (
	"INSERT INTO torder VALUES (5501, 8, '2000-11-29',0)",
	"INSERT INTO torder VALUES (5502, 29, '2000-11-29',0)",
	
	"INSERT INTO ordered_articles VALUES (5501, 8, 2)", 
	"INSERT INTO ordered_articles VALUES (5501, 20, 10)",
	"INSERT INTO ordered_articles VALUES (5502, 7, 10)",
	"INSERT INTO ordered_articles VALUES (5502, 35, 1)",
	"INSERT INTO ordered_articles VALUES (5502, 38, 2)",
	
	"COMMIT"
	);
	

  	my $henv = DTFHANDLE_NULL; 	# environment handle
  	my $hcon = DTFHANDLE_NULL; 	# connection handle
  	my $htra = DTFHANDLE_NULL; 	# transaction handle

  	my $err = DTF_ERR_OK;		# error code
  	my $errstr = '';			# error string  


 	 print "\n",
        "dtF/SQL - Create a sample database\n",
        "----------------------------------------------------------------------\n",
        " +++ creates the sample database 'SampleDB.dtf' in the current folder\n", 
		" +++ user 'dtfadm' | password 'dtfadm'\n\n";
		

  	#  First, we create all needed handles:
  	#  an environment and a connection handle (but do not connect).


  	if ( ($err = DtfEnvCreate($henv) ) != DTF_ERR_OK) {
  		die "\n# ERROR: Can't create environment [errcode: $err]";
  	}

  	print "Ok, environment handle created ...\n";

  	#  When the environment handle (henv) was created successfully,  a connection handle
  	#  can be created as the environment handle's *dependent* handle.
  	#
  	#  Note: The function DtfConCreateDatabase is correctly implemented only in the single-user version of
  	#  dtF/SQL.
  
  	my $curdir = `pwd`;
	chomp $curdir;
	$curdir =~ s/:$//; # get rid of trailing colon
  	my $dsn = $curdir . ':SampleDB.dtf'; # Data Source Name DSN
  
  	if (DtfConCreate($henv, $dsn, DTF_CF_FILENAME, $hcon) != DTF_ERR_OK) {
    	die "\n# ERROR: Can't create a connection handle";
  	}

  	print "Ok, connection handle created ...\n";
  
  	#  This function queries some information about the just established connection

  	my $connected = NULL;
  	my $dbExists = not_NULL; # not NULL is important
  	my $dbConsistent = not_NULL;	# not NULL is important
  
  	if ( ($err = DtfConQueryStatus($hcon, NULL, $dbExists, NULL) ) != DTF_ERR_OK) {
    	die "\n# ERROR: Can't query connection status [errcode: $err]";
  	}

  	my $indexSize = 0;
 	my $relationSize = 0;
 	my $user = "dtfadm";
  	my $password = "dtfadm";
  
  	if ($dbExists) {
  		die "\n# ERROR: Database " . $dsn . " does already exist";
  	} else {
  		if ( ($err = DtfConCreateDatabase(	$hcon,
                             				$user,
                             				$password,
                              				0,        			# default index/relation ratio (25:75)
                             				DTF_MAX_MAXSIZE, 	# maximum database file size
                              				$indexSize,   		# resulting index size [KB]
                              				$relationSize    	# resulting relation size [KB]
                              			 ) ) != DTF_ERR_OK)
        {
          	die "\n# ERROR: Can't create database [errcode: $err]";
        }#if
	
  		print "\nDatabase was created successfully.\n",
          "  Space for index      data: " . $indexSize . " KB\n",
          "  Space for relational data: " . $relationSize . " KB\n\n";
		
  	}#if
  
  	#
  	# Now insert test data
  	#
  
  
  	#  first, connect as user ...
  
  	if ( ($err = DtfConConnect($hcon, $user, $password) ) != DTF_ERR_OK) {
    	die "\n# ERROR: Can't connect as " . $user;
  	}
  	print "Ok, connected as user $user ...\n";
  
  
  	#  We are connected, now create a transaction we are able
  	#  to execute SQL statements with.

  
  	if ($err = DtfTraCreate( $hcon, $htra ) != DTF_ERR_OK) {
    	die "\n# ERROR: Can't create transaction";
  	}
  
  	print "Ok, transaction started ...\n\n";
    
   	# check the auto commit mode and display it to the user (default = OFF)

	my $false_or_true;
	DtfHdlQueryAttribute($htra, DTF_TAT_AUTOCOMMIT, $false_or_true);
	print "auto-commit = $false_or_true.\n\n";
  
 	# everything is fine here
 
  	print "Inserting test data started ...\n\n\n";
  
  	# prepare and execute a statement
  
  	my $affectedRecords; # no. of affected records

  	#
	# create user tables 'Address' and 'Articles '
	#
	my $statement = '';
	
	foreach $statement (@statements) { 
		print $statement, "\n";
		if (DtfTraExecuteUpdate($htra, $statement, $affectedRecords) != DTF_ERR_OK) {
      		#  Any errors resulted from the SQL request
      		#  will be displayed here.

      		my $code;   # error code
      		my $msg; 	# error message
      		my $grp;  	# error group
      		my $errpos; # error position within the SQL request
	
      		if (DtfHdlGetError($htra, $code, $msg, $grp, $errpos) != DTF_ERR_OK) {
      	 	 die "\n# ERROR: Can't query transaction error";
      		}
      		printf("\n# SQL-ERR(%x): %s: %s.\n\n", $code, $grp, $msg);
      		die;
  		}#if
	}#for
  	print "\n+++\n\n";

	#
	# address table
	#
	
	
    for(my $i = 0; $i < 40; $i++) {
	
		my $lnindex = $i % 15;		
		my $fnindex = $i % 18;
		my $stindex = $i % 6;
		my $cindex = $i % 12;
		
		$statement = "INSERT INTO clients VALUES(". ($i + 1) .", '". $firstname[$fnindex] 
		              . "', '". $lastname[$lnindex] . "', '" . $street[$stindex]. ($cindex + 1) 
					  ."', '" . $city[$cindex]. "')";
  
		print $statement, "\n";
		if (DtfTraExecuteUpdate($htra, $statement, $affectedRecords) != DTF_ERR_OK) {
      		#  Any errors resulted from the SQL request
      		#  will be displayed here.

      		my $code;   # error code
      		my $msg; 	# error message
      		my $grp;  	# error group
      		my $errpos; # error position within the SQL request
	
      		if (DtfHdlGetError($htra, $code, $msg, $grp, $errpos) != DTF_ERR_OK) {
      	 	 die "\n# : Can't query transaction error";
      		}
			printf("\n# SQL-ERR(%x): %s: %s.\n\n", $code, $grp, $msg);
      		die;
  		}#if

 	}#for
  	print "\n+++\n\n";

	#
	# articles table
	#
	
	my $x = 1;
	foreach my $article (@articles) {
	 	$statement = "INSERT INTO articles VALUES(" . $x . ", " . $article . ")";
	 	$x++;
	 	print $statement , "\n";
		if (DtfTraExecuteUpdate($htra, $statement, $affectedRecords) != DTF_ERR_OK) {
      		#  Any errors resulted from the SQL request
      		#  will be displayed here.

      		my $code;   # error code
      		my $msg; 	# error message
      		my $grp;  	# error group
      		my $errpos; # error position within the SQL request
	
      		if (DtfHdlGetError($htra, $code, $msg, $grp, $errpos) != DTF_ERR_OK) {
      	 	 die "\n# ERROR: Can't query transaction error";
      		}
			printf("\n# SQL-ERR(%x): %s: %s.\n\n", $code, $grp, $msg);
			die;
  		}#if
	}#for

  	print "\n+++\n\n";
	
	#
	# order statements with COMMIT
 	#
	
	
	foreach my $statement (@order_statements) {
	 	print $statement , "\n";
		if (DtfTraExecuteUpdate($htra, $statement, $affectedRecords) != DTF_ERR_OK) {
      		#  Any errors resulted from the SQL request
      		#  will be displayed here.

      		my $code;   # error code
      		my $msg; 	# error message
      		my $grp;  	# error group
      		my $errpos; # error position within the SQL request
	
      		if (DtfHdlGetError($htra, $code, $msg, $grp, $errpos) != DTF_ERR_OK) {
      	 	 die "\n# ERROR: Can't query transaction error";
      		}
			printf("\n# SQL-ERR(%x): %s: %s.\n\n", $code, $grp, $msg);
			die;
  		}#if
	}#for

	print "\n\n+++ Ok, end of data insertion +++\n";
	
		
	#
	# now, disconnect from the database
	#

	print "\n\nDisconnecting ...\n";
	($err, $errstr) = dtf_disconnect ($henv, $hcon, $htra);
	if ($err) {
		die "\n# " . $errstr;
	}
		
	print "\n... ok.\n";
	
	1;
	

