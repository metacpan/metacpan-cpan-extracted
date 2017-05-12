#!/usr/bin/perl -w
#
# Last Update:            $Author: marvin $
# Update Date:            $Date: 2007/12/10 17:54:22 $
# Source File:            $Source: /home/cvsroot/tools/FileSystem/t/02_access_data.t,v $
# CVS/RCS Revision:       $Revision: 1.3 $
# Status:                 $State: Exp $
#
use strict;
use Test::More tests => 127;

# load your module...
use DBIx::FileSystem qw( :symbols );

###
### NOTE: change these three vars to so that they are 'pointing' to the 
###	  test database created with 'pawactl recreatedb'. Use the same 
###	  settings like in 'pawactl'.
###
my $DBCONN = "dbi:Pg:dbname=warehouse;host=vinmari";
my $DBUSER = "marvin";
my $DBPWD  = undef;

my $PROGDBVER = "0002";

###
### NOTE: these setting point to a not existing database for testing
###
my $DBCONN_WRONG = "${DBCONN}.bla.local";


# first check, if db is available and we can do tests...
my $has_db = 0;
my $fs;
eval{ $fs = new DBIx::FileSystem( dbconn => $DBCONN,
				  dbuser => $DBUSER,
				  dbpasswd => $DBPWD,
				  progdbver => $PROGDBVER );
};
if( defined $fs and $fs->database_bad() == 0 ) {
  $has_db = 1;
  $fs->{dbh}->disconnect();
}


# now do the tests
SKIP: {
  skip "no database for testing available", 127 if $has_db == 0;

  my $r;
  my %vars;
  my %svars;

  ########################################################################
  ### connect
  ########################################################################

  $fs = new DBIx::FileSystem( dbconn => $DBCONN_WRONG,
			      dbuser => $DBUSER,
			      dbpasswd => $DBPWD,
			      progdbver => $PROGDBVER );

  ok( defined $fs, "get object" );
  ok( $fs->database_bad() == 1, "connect: wrong host & db" );
  # do not check err-message here: its database dependend


  ########################################################################
  $fs = new DBIx::FileSystem( dbconn => $DBCONN,
			      dbuser => "the_unknown_userr",
			      dbpasswd => $DBPWD,
			      progdbver => $PROGDBVER );

  ok( defined $fs, "get object" );
  ok( $fs->database_bad() == 1, "connect: wrong user" );
  # do not check err-message here: its database dependend


  ########################################################################
  $fs = new DBIx::FileSystem( dbconn => $DBCONN,
			      dbuser => $DBUSER,
			      dbpasswd => $DBPWD,
			      progdbver => "42abc" );

  ok( defined $fs, "get object" );
  ok( $fs->database_bad() == 1, "connect: wrong db version" );
  like( $fs->get_err, 
	"/^version mismatch: program <--> db /",
	"wrong db version: err message" );

  ########################################################################
  %vars = ( fname => undef, itim => undef );
  %svars = ( fname => "um5333" );
  $r = $fs->get_conf_by_var( "warehouse", undef, "fname", \%vars, \%svars );
  is( $r, ERROR, "wrong db version + query" );
  like( $fs->get_err, '/^DBIx::FileSystem object not initialized/', 
	"wrong db version + query: err message" );

  ########################################################################
  $fs = new DBIx::FileSystem( dbconn => $DBCONN,
			      dbuser => $DBUSER,
			      dbpasswd => $DBPWD,
			      progdbver => $PROGDBVER );
  ok( defined $fs, "get object" );
  ok( $fs->database_bad() == 0, "connect: ok" );



  ########################################################################
  ### query: get_conf_by_var() without defaultfile
  ########################################################################


  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, addr => undef, delay1 => undef, delay2 => undef,
	    opt => undef, mps => undef );
  %svars = ( fname => "venus" );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
  is( $r, OK, 			"get(): 1 var: status" );
  is( $vars{fname}, "venus",	"get(): 1 var: result fname" );
  is( $vars{addr}, "direction sun", "get(): 1 var: result addr" );
  is( $vars{delay1}, 33,	"get(): 1 var: result delay1" );
  is( $vars{delay2}, 12,	"get(): 1 var: result delay2" );
  is( $vars{opt},     1,	"get(): 1 var: result opt" );
  is( $vars{mps},    67,	"get(): 1 var: result mps" );


  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname => "venus", delay1 => 33 );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
  is( $r, OK, 			"get(): 2 var: status" );
  is( $vars{fname}, "venus", 	"get(): 2 var: result fname" );
  is( $vars{delay1}, 33, 	"get(): 2 var: result delay1" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname => "venus", delay1 => 33, delay2 => 12 );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
  is( $r, OK, 			"get(): 3 var: status" );
  is( $vars{fname}, "venus", 	"get(): 3 var: result fname" );
  is( $vars{delay1}, 33, 	"get(): 3 var: result delay1" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname =>  [ "=", "venus"	], 
	     delay1 => [ "=", 33 	], 
	     delay2 => [ "=", 12	] );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
  is( $r, OK, 			"get(): 3 var+cmp: status" );
  is( $vars{fname}, "venus", 	"get(): 3 var+cmp: result fname" );
  is( $vars{delay1}, 33, 	"get(): 3 var+cmp: result delay1" );
  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname =>  [ "=", "venus"	], 
	     delay1 => [ "=", 33 	], 
	     delay2 => [ ">", 12	] );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
  is( $r, NOFILE,	   "get(): 3 var+cmp+mismatch: status" );
  is( $vars{fname},undef,  "get(): 3 var+cmp+mismatch: result fname" );
  is( $vars{delay1},undef, "get(): 3 var+cmp+mismatch: result delay1" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname => [ "===", "venus"	] );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
  is( $r, ERROR,	  "get(): 1 var+broken cmp: status" );
  is( $vars{fname},undef, "get(): 1 var+broken cmp: result fname" );
  is( $vars{delay1},undef,"get(): 1 var+broken cmp: result delay1" );

 SKIP: {
    skip "'net' and 'cidr' olny work with PostgreSQL", 6 unless $DBCONN =~ /^dbi:Pg:/;
    ########################################################################
    %vars = ( ); %svars = ( );
    %vars = ( fname => undef, delay1 => undef );
    %svars = ( fname =>  [ "=", "venus"	],
	       remnet => [ ">>", "10.20.40.50" ]);
    $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
    is( $r, OK,	       	      "get(): 2 var+match host: status" );
    is( $vars{fname},"venus", "get(): 2 var+match host: result " );

    ########################################################################
    %vars = ( ); %svars = ( );
    %vars = ( fname => undef, delay1 => undef );
    %svars = ( fname =>  [ "=", "venus"	],
	       remnet => [ ">>", "100.20.40.50" ]);
    $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
    is( $r, NOFILE,	    "get(): 2 var+match no host: status" );
    is( $vars{fname},undef, "get(): 2 var+match no host: result " );

    ########################################################################
    %vars = ( ); %svars = ( );
    %vars = ( fname => undef, delay1 => undef );
    %svars = ( delay1 => [ "=", 33	],
	       remnet => [ ">>", "10.20.40.50" ]);
    $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
    is( $r, NFOUND,	    "get(): 2 var+match 2 hosts: status" );
    is( $vars{fname},undef, "get(): 2 var+match 2 hosts: result " );

  }

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( delay1 => [ "=", "xyz"	], );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
  is( $r, ERROR,	    "get(): wrong int val: status" );
  is( $vars{fname},undef,   "get(): wrong int val: result " );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname => "venus" );
  $r = $fs->get_conf_by_var( "dest", "nonexist", "fname", \%vars, \%svars );
  like( $fs->get_err, "/^defaultfile 'dest/nonexist' not found/",
	"get(): nonexist default: err message" );
  is( $r, ERROR,	    "get(): nonexist default: status" );
  is( $vars{fname}, undef,  "get(): nonexist default: result" );



  ########################################################################
  ### query: get_conf_by_var() with defaultfile, no defaultvalue in query
  ########################################################################


  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, code => undef );
  %svars = ( fname => "factory2" );
  $r = $fs->get_conf_by_var( "source", "generic", "fname", \%vars, \%svars );
  is( $r,OK,	    	      "get(): 1 var, no default: status" );
  is( $vars{fname},"factory2","get(): 1 var, no default: result" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, sendto => undef );
  %svars = ( fname => "kcity" );
  $r = $fs->get_conf_by_var( "source", "generic", "fname", \%vars, \%svars );
  is( $r,OK,	    	   "get(): 1 var, default NULL: status" );
  is( $vars{fname},"kcity","get(): 1 var, default NULL: result" );
  is( $vars{sendto},undef, "get(): 1 var, default NULL: result" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, prop => undef );
  %svars = ( fname => "generic" );
  $r = $fs->get_conf_by_var( "source", "generic", "fname", \%vars, \%svars );
  is( $r,OK,	    	     "get(): 1 var, read default w.default: status" );
  is( $vars{fname},"generic","get(): 1 var, read default w.default: result" );
  is( $vars{prop}, 80,       "get(): 1 var, read default w.default: result" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, prop => undef );
  %svars = ( fname => "generic" );
  $r = $fs->get_conf_by_var( "source", undef, "fname", \%vars, \%svars );
  is( $r,OK,	    	     "get(): 1 var, read default w/o default: status" );
  is( $vars{fname},"generic","get(): 1 var, read default w/o default: result" );
  is( $vars{prop}, 80,       "get(): 1 var, read default w/o default: result" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, code => undef, dist => undef );
  %svars = ( code => "D", dist => 3000  );
  $r = $fs->get_conf_by_var( "source", "generic", "fname", \%vars, \%svars );
  is( $r,OK,	    	      "get(): 2 var, no defvals in query: status" );
  is( $vars{fname},"factory2","get(): 2 var, no defvals in query: result" );
  is( $vars{code}, "D",       "get(): 2 var, no defvals in query: result" );
  is( $vars{dist}, 3000,      "get(): 2 var, no defvals in query: result" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, code => undef, dist => undef );
  %svars = ( code => "E", dist => undef  );
  $r = $fs->get_conf_by_var( "source", "generic", "fname", \%vars, \%svars );
  is( $r,OK, 			"get(): 2 var, NULL in qry, result != NULL, default: status" );
  is( $vars{fname},"factory1",  "get(): 2 var, NULL in qry, result != NULL, default: result" );
  is( $vars{code}, "E", 	"get(): 2 var, NULL in qry, result != NULL, default: result" );
  is( $vars{dist}, 1000, 	"get(): 2 var, NULL in qry, result != NULL, default: result" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, code => undef, dist => undef );
  %svars = ( code => "E", dist => undef  );
  $r = $fs->get_conf_by_var( "source", undef, "fname", \%vars, \%svars );
  is( $r,OK, 			"get(): 2 var, NULL in qry, result != NULL, nodefault: status" );
  is( $vars{fname},"factory1",  "get(): 2 var, NULL in qry, result != NULL, nodefault: result" );
  is( $vars{code}, "E", 	"get(): 2 var, NULL in qry, result != NULL, nodefault: result" );
  is( $vars{dist}, undef, 	"get(): 2 var, NULL in qry, result != NULL, nodefault: result" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, sendto => undef );
  %svars = ( code => "E", sendto => undef  );
  $r = $fs->get_conf_by_var( "source", "generic", "fname", \%vars, \%svars );
  is( $r,OK, 			"get(): 2 var, NULL in qry & result, default: status" );
  is( $vars{fname},  "kcity",  	"get(): 2 var, NULL in qry & result, default: result" );
  is( $vars{sendto}, undef, 	"get(): 2 var, NULL in qry & result, default: result" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, sendto => undef );
  %svars = ( code => "E", sendto => undef  );
  $r = $fs->get_conf_by_var( "source", undef, "fname", \%vars, \%svars );
  is( $r,OK, 			"get(): 2 var, NULL in qry & result, nodefault: status" );
  is( $vars{fname},  "kcity",  	"get(): 2 var, NULL in qry & result, nodefault: result" );
  is( $vars{sendto}, undef, 	"get(): 2 var, NULL in qry & result, nodefault: result" );



  ########################################################################
  ### query: get_conf_by_var() with defaultfile, with defaultvalue in query & result
  ########################################################################



  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, code => undef );
  %svars = ( code => "D", dist => 1000  );
  $r = $fs->get_conf_by_var( "source", "generic", "fname", \%vars, \%svars );
  is( $r,NFOUND, 		"get(): 2 var, default in qry, nfound: status" );
  is( $vars{fname},  undef,  	"get(): 2 var, default in qry, nfound: result" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, code => undef, dist => undef );
  %svars = ( code => "D", dist => 2000  );
  $r = $fs->get_conf_by_var( "source", "generic", "fname", \%vars, \%svars );
  is( $r,OK, 			"get(): 2 var, default in qry, ok: status" );
  is( $vars{fname},  "bcity",  	"get(): 2 var, default in qry, ok: result" );
  is( $vars{code},   "D",  	"get(): 2 var, default in qry, ok: result" );
  is( $vars{dist},   2000,  	"get(): 2 var, default in qry, ok: result" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, code => undef, dist => undef );
  %svars = ( code => "D", dist => 3000  );
  $r = $fs->get_conf_by_var( "source", "generic", "fname", \%vars, \%svars );
  is( $r,OK, 			"get(): 2 var, no default in qry, ok: status" );
  is( $vars{fname},  "factory2","get(): 2 var, no default in qry, ok: result" );
  is( $vars{code},   "D",  	"get(): 2 var, no default in qry, ok: result" );
  is( $vars{dist},   3000,  	"get(): 2 var, no default in qry, ok: result" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, code => undef, dist => undef );
  %svars = ( code => "E", dist => 1000  );
  $r = $fs->get_conf_by_var( "source", "generic", "fname", \%vars, \%svars );
  is( $r,OK, 			"get(): 2 var, default in qry, ok: status" );
  is( $vars{fname},  "factory1","get(): 2 var, default in qry, ok: result" );
  is( $vars{code},   "E",  	"get(): 2 var, default in qry, ok: result" );
  is( $vars{dist},   1000,  	"get(): 2 var, default in qry, ok: result" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, code => undef, dist => undef );
  %svars = ( code => "E", dist => 4000  );
  $r = $fs->get_conf_by_var( "source", "generic", "fname", \%vars, \%svars );
  is( $r,NOFILE, 		"get(): 2 var, default in qry, nofile: status" );
  is( $vars{fname},  undef,	"get(): 2 var, default in qry, nofile: result" );



  ########################################################################
  ### parameter checking
  ########################################################################






  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname => "venus", delay1 => 33, delay2 => 12 );
  $r = $fs->get_conf_by_var( "nonexitdir", undef, "fname", \%vars, \%svars );
  is( $r, ERROR, 		"get(): 3 var, wrong dir: status" );
  is( $vars{fname}, undef, 	"get(): 3 var, wrong dir: result fname" );
  like( $fs->get_err, '/relation "nonexitdir" does not exist/', 
	"get(): 3 var, wrong dir: err message" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname => "venus", delay1 => 33, delay2 => 12 );
  $r = $fs->get_conf_by_var( "", undef, "fname", \%vars, \%svars );
  is( $r, ERROR, 		"get(): 3 var, dir empty: status" );
  is( $vars{fname}, undef, 	"get(): 3 var, dir empty: result fname" );
  like( $fs->get_err, "/parameter 'dir' is empty/", 
	"get(): 3 var, dir empty: err message" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname => "venus", delay1 => 33, delay2 => 12 );
  $r = $fs->get_conf_by_var( undef, undef, "fname", \%vars, \%svars );
  is( $r, ERROR, 		"get(): 3 var, dir undef: status" );
  is( $vars{fname}, undef, 	"get(): 3 var, dir undef: result fname" );
  like( $fs->get_err, "/parameter 'dir' is empty/", 
	"get(): 3 var, dir undef: err message" );


  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname => "venus", delay1 => 33, delay2 => 12 );
  $r = $fs->get_conf_by_var( "dest", undef, "", \%vars, \%svars );
  is( $r, ERROR, 		"get(): 3 var, fnamcol empty: status" );
  is( $vars{fname}, undef, 	"get(): 3 var, fnamcol empty: result fname" );
  like( $fs->get_err, "/parameter 'fnamcol' is empty/", 
	"get(): 3 var, fnamcol empty: err message" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname => "venus", delay1 => 33, delay2 => 12 );
  $r = $fs->get_conf_by_var( "dest", undef, undef, \%vars, \%svars );
  is( $r, ERROR, 		"get(): 3 var, fnamcol undef: status" );
  is( $vars{fname}, undef, 	"get(): 3 var, fnamcol undef: result fname" );
  like( $fs->get_err, "/parameter 'fnamcol' is empty/", 
	"get(): 3 var, fnamcol undef: err message" );


  ########################################################################
  %vars = ( ); %svars = ( );
  %svars = ( fname => "venus", delay1 => 33, delay2 => 12 );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
  is( $r, ERROR, 		"get(): 3 var, #elem vars=0: status" );
  is( $vars{fname}, undef, 	"get(): 3 var, #elem vars=0: result fname" );
  like( $fs->get_err, "/hash 'vars' is empty/", 
	"get(): 3 var, #elem vars=0: err message" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
  is( $r, ERROR, 		"get(): 3 var, #elem svars=0: status" );
  is( $vars{fname}, undef, 	"get(): 3 var, #elem svars=0: result fname" );
  like( $fs->get_err, "/hash 'searchvars' is empty/", 
	"get(): 3 var, #elem svars=0: err message" );





  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname => "venus", delay1 => 33, delay2 => 12 );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", %vars, \%svars );
  is( $r, ERROR, 		"get(): 3 var, vars not hashref: status" );
  is( $vars{fname}, undef, 	"get(): 3 var, vars not hashref: result fname" );
  like( $fs->get_err, "/parameter 'vars' is no hashref/", 
	"get(): 3 var, vars not hashref: err message" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname => "venus", delay1 => 33, delay2 => 12 );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, %svars );
  is( $r, ERROR, 		"get(): 3 var, searchvars not hashref: status" );
  is( $vars{fname}, undef, 	"get(): 3 var, searchvars not hashref: result fname" );
  like( $fs->get_err, "/parameter 'searchvars' is no hashref/", 
	"get(): 3 var, searchvars not hashref: err message" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname => "venus", delay1 => 33, delay2 => { x => 1, y => 2 } );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
  is( $r, ERROR, 		"get(): 3 var, compare not arrayref: status" );
  is( $vars{fname}, undef, 	"get(): 3 var, compare not arrayref: result fname" );
  # platofrm dependend error message from db: "compare int
  like( $fs->get_err, "/query: /", "get(): 3 var, compare not arrayref: err message" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname => "venus", delay1 => 33, delay2 => [ '=', 12 ] );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
  is( $r, OK, 			"get(): 3 var, compare mix: status" );
  is( $vars{fname}, "venus", 	"get(): 3 var, compare mix: result fname" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( fname => "ven'us", delay1 => 33, delay2 => 12  );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
  is( $r, NOFILE, 		"get(): 3 var, quote in param, nofile: status" );
  is( $vars{fname}, undef, 	"get(): 3 var, quote in param, nofile: result fname" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( comment => "bright and big and with a quote ' here" );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
  is( $r, OK, 			"get(): 3 var, quote in param, ok: status" );
  is( $vars{fname}, "sun", 	"get(): 3 var, quote in param, ok: result fname" );

  ########################################################################
  %vars = ( ); %svars = ( );
  %vars = ( fname => undef, delay1 => undef );
  %svars = ( comment => [ 'LIKE',  '%quote \' here%' ] );
  $r = $fs->get_conf_by_var( "dest", undef, "fname", \%vars, \%svars );
  is( $r, OK, 			"get(): 3 var, quote in param, like, ok: status" );
  is( $vars{fname}, "sun", 	"get(): 3 var, quote in param, like, ok: result fname" );






}
