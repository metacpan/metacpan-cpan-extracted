# -*- perl -*-
#
# $Id: Makefile.PL,v 11.91 2002/12/13 23:44:56 tlowery Exp $
#
#  Copyright (c) 1994,1995,1996,1997  Tim Bunce  England
#
# See COPYRIGHT section in DBI.pm for usage and distribution rights.

BEGIN {
    require 5.004;
    unshift @INC, "lib";
}

use ExtUtils::MakeMaker 5.16, qw(WriteMakefile $Verbose);
use Getopt::Long;
use Config;

use Test::Harness;	# tests use it so check it's loadable early


my $os = $^O;
my $osvers = $Config{osvers};
$osvers =~ s/^\s*(\d+\.\d+).*/$1/;  # drop sub-sub-version: 2.5.1 -> 2.5
my $ext_pl = $^O eq 'VMS' ? '.pl' : '';

$::opt_v = 0;
$::opt_g = 0;
$::opt_thread = 1;	# unset later if not a threaded perl

GetOptions(qw(v! g! thread!))
	or die "Invalid arguments\n";

$::opt_g &&= '-g';  # convert to actual string

    $::opt_thread = 0;
 
%opts = (
    NAME=> 'DBI::Shell',
    VERSION_FROM=> 'lib/DBI/Shell.pm',
    EXE_FILES => [ "dbish$ext_pl" ],
    DIR => [],
    dynamic_lib => { OTHERLDFLAGS => "$::opt_g" },
    clean => { FILES=> "dbish$ext_pl  ndtest.prt" },
    dist  => {
	DIST_DEFAULT=> 'clean distcheck disttest ci tardist',
	PREOP => '$(MAKE) -f Makefile.old distdir',
	COMPRESS => 'gzip -v9', SUFFIX => 'gz',
    },
	PREREQ_PM   => {
		  Test::More	=> 0.0
		, IO::Tee		=> 0.0
		, Text::Reform	=> 0.0
	},
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ABSTRACT_FROM} = 'lib/DBI/Shell.pm';
    $opts{AUTHOR} = 'Thomas A. Lowery (tlowery@cpan.net) and host of others.';
    $opts{CAPI} = 'TRUE' if $Config{archname} =~ /-object\b/i;
}

$Verbose = $::opt_v;
WriteMakefile( %opts );

# =====================================================================

# $Log: Makefile.PL,v $
# Revision 11.91  2002/12/13 23:44:56  tlowery
# Fixed version numbers
#
# Revision 11.9  2002/12/07 14:26:34  tlowery
# Added pre-req to Makefile.PL
#
# Revision 11.8  2002/11/26 18:43:20  tlowery
# Removed warning message from Makefile.PL
#
# Revision 11.7  2002/11/05 16:02:04  tlowery
# Release added spool and pagesize
#
# Revision 11.6  2002/10/28 02:49:57  tlowery
# Release 11.6
#
# Revision 11.5  2002/04/17 15:03:16  tlowery
# Added the begining of column_info support.
#
# Revision 11.4  2002/04/09 10:52:12  tlowery
# Continued to improve support for formatting.  Added more tests.
#
# Revision 11.3  2002/01/02 03:14:59  tlowery
# Modified to include new formats.
#
# Changed displaymode to format.
#
# Cleaned up a number of "undefined" messages.
#
# Revision 11.2  2001/10/29 15:56:00  tlowery
# Added timing tests.
# Added go with empty buffer gets the last command and executes.
# Added support for negative numbers with get.
# Fixed undef warnings from histories.
#
# Revision 1.4  2001/04/06 09:32:22  tlowery
#
# Added CVS tags.
#
#
