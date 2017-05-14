#!/usr/local/bin/perl -w
#
# Makefile.PL
#
# $Id: Makefile.PL,v 1.1 2003/02/02 16:31:22 awolf Exp $
# $Revision: 1.1 $
# $Author: awolf $
# $Date: 2003/02/02 16:31:22 $
#
######################################################################

use 5.6.0;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my $NAME     = 'DNS-Zone';
my $VERSION  = '0.85';

#--- Prototypes ---#
sub check_makefile_exists( );

#--------------------------------------------#

die "Exiting due to existing makefile..." if check_makefile_exists();

WriteMakefile(
	'NAME'      => $NAME,
	'VERSION'   => $VERSION,
	'DISTNAME'  => $NAME,
	($] >= 5.005 ? (
		AUTHOR    => 'Andy Wolf <zonemaster@users.sourceforge.net>',
		ABSTRACT  => 'Generic zone with specific file adaptors'
	) : ()),
	'MAN3PODS' => { }
);

exit 0;

#--- Check for existing Makefile ---#
sub check_makefile_exists( ) {
	my $answer = 0;
	
	if (-e 'Makefile') {
		warn <<END;
There is already a Makefile.  To avoid weird problems it is
recommended you run 'make distclean' to clear out old built files
before generating a new Makefile.

END

		$answer = ExtUtils::MakeMaker::prompt('Do you wish to continue anyway ?', 'no');
		
	}

	return ($answer =~ /^n[o]*$/i) ? 1 : 0;
}

1;