#
# Installation Makefile for DBD::DtfSQLmac and MacPerl 5.2.0r4 or 5.6.1
#
# Author: Thomas Wegner 
# Date: 2002-April-06
#

#!perl -w

use ExtUtils::MakeMaker;
use File::Copy;
use File::Path;


print "\n\nInstall DBD::DtfSQLmac and the interface module Mac::DtfSQL ...\n\n";

if ($^O eq 'MacOS') {
	print "OS is $^O.\n";
} else {
	die "This module is for Mac OS only. Your OS is $^O.";
}


print <<EOT_README;


ReadMe ...


*** PLEASE NOTE                                  (You have to do this manually)
================================================================================
             
The Mac::DtfSQL module needs the dtF/SQL 2.01 shared library for PPC in order 
to work. This lib has to be placed in the proper location on your harddisk: 

After installation of this module, either put the dtF/SQL 2.01 shared library 
dtFPPCSV2.8K.shlb (or at least an alias to it) in the *SAME* folder as the 
shared library DtfSQL built from the interface module (by default the folder 
is :MacPerlÄ:site_perl:MacPPC:auto:Mac:DtfSQL:) or put the dtF/SQL 2.01 shared 
library in the *System Extensions* folder.

================================================================================



EOT_README


undef $@;
eval 'use DBI 1.08';

if ($@) {
    print <<EOT;
	
The DBI module is not installed on your Macintosh.

If you want to install DBD::DtfSQLmac, you must install DBI before installing this 
driver. Visit the MacPerl Module Porters page (http://dev.macperl.org/mmp/) to get 
a copy of DBI 1.08 for MacPerl 5.2.0r4 or a copy of DBI 1.21 for MacPerl 5.6.1 (or
higher). 

Exit.

EOT
	
	exit (1);
}#if


print "Found DBI version $DBI::VERSION.\n\n";

if ($] < 5.006) {
	# prepare install blib for old MacPerl 5.2.0r4
	print "Preparing installation blib for MacPerl 5.2.0r4 ... \n";
	mkpath(':blib:lib:MacPPC:auto:Mac:DtfSQL:', 1);
	print "copying :MacPerl-5.2.0r4:DtfSQL -> :blib:lib:MacPPC:auto:Mac:DtfSQL:DtfSQL \n";
	copy(':MacPerl-5.2.0r4:DtfSQL', ':blib:lib:MacPPC:auto:Mac:DtfSQL:DtfSQL');
	print "ok.\n\n"

} else {
	# prepare install blib for MacPerl 5.6.1 and higher
	print "Preparing installation blib for MacPerl 5.6.1 (or higher) ... \n";
	mkpath(':blib:lib:MacPPC:auto:Mac:DtfSQL:', 1);
	print "copying :MacPerl-5.6.1:DtfSQL -> :blib:lib:MacPPC:auto:Mac:DtfSQL:DtfSQL \n";
	copy(':MacPerl-5.6.1:DtfSQL', ':blib:lib:MacPPC:auto:Mac:DtfSQL:DtfSQL');
	print "ok.\n\n";
} 


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'Mac::DtfSQL',
	'DISTNAME' => 'DBD::DtfSQLmac', 
    'VERSION_FROM' => 'DtfSQL.pm', # finds $VERSION
);
