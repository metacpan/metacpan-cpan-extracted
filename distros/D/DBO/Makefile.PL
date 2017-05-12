#------------------------------------------------------------------------------
# Makefile.PL for DBO - Database Objects
#
# AUTHOR
#   Gareth Rees
#
# COPYRIGHT
#   Copyright (c) 1999 Canon Research Centre Europe Ltd/
#
# $Id: Makefile.PL,v 1.1 1999/06/04 21:56:09 garethr Exp $
#------------------------------------------------------------------------------

use strict;
use Data::Dumper;
use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use vars qw($CONFIG @PARAMETERS);

# Interrogate the user for the test configuration details (which will be
# collected in the $CONFIG hashref and then saved in the .status file in
# the current directory).  The configuration parameters are described in
# the @PARAMETERS array

$CONFIG =
  {
   driver   => 'mSQL',
   database => '',
   user     => '',
   password => '',
  };

foreach (@PARAMETERS) {
  $CONFIG->{$_->[0]} = $_->[2];
}

# Load the previous configuration if it exists.

require '.status' if -f '.status';

# Prompt the user for the configuration details.

$CONFIG->{driver}
  = prompt("Name of the DBI driver for the test database?",
	   $CONFIG->{driver});

$CONFIG->{datasource}
  = prompt("Datasource name for the test database?",
	   $CONFIG->{datasource} || "dbi:$CONFIG->{driver}:test:localhost");

$CONFIG->{user}
  = prompt("User name for connecting to $CONFIG->{datasource}?",
	   $CONFIG->{user});

$CONFIG->{password}
  = prompt("Password for connecting to $CONFIG->{datasource}?",
	   $CONFIG->{password});

# Write configuration to .status

open STATUS, '> .status'
  and print STATUS Data::Dumper->Dump([$CONFIG], ['$CONFIG'])
  and close STATUS
  or die "Cannot create .status file: $!\n";

WriteMakefile
  (
   NAME		=> 'DBO',
   PREREQ_PM    => { DBI => 0,
		     "DBD::$CONFIG->{driver}" => 0,
		     'Class::Multimethods' => 0,
		     'HTML::FromText' => 0,
		   },
   VERSION_FROM	=> 'lib/DBO.pm',
   dist		=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
   realclean	=> { FILES => '.status' },
  );
