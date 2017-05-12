###############################################################################
#
#                BUNGISOFT, INC.
#
#			      PROPRIETARY DATA
#
#  THIS DOCUMENT CONTAINS TRADE SECRET DATA WHICH IS THE PROPERTY OF
#  BUNGISOFT, INC. THIS DOCUMENT IS SUBMITTED TO RECIPIENT IN
#  CONFIDENCE. INFORMATION CONTAINED HEREIN MAY NOT BE USED, COPIED OR
#  DISCLOSED IN WHOLE OR IN PART EXCEPT AS PERMITTED BY WRITTEN AGREEMENT
#  SIGNED BY AN OFFICER OF BUNGISOFT, INC.
#
#  THIS MATERIAL IS ALSO COPYRIGHTED AS AN UNPUBLISHED WORK UNDER
#  SECTIONS 104 AND 408 OF TITLE 17 OF THE UNITED STATES CODE.
#  UNAUTHORIZED USE, COPYING OR OTHER REPRODUCTION IS PROHIBITED BY LAW.
#
#  Copyright (c) 2002 Bungisoft, Inc.
#
#  Version: $Id: Makefile.PL,v 1.2 2002/08/20 21:22:18 ilya Exp $
#
###############################################################################

use DBI;
use DBI::DBD;
use ExtUtils::MakeMaker;

WriteMakefile
(
	dbd_edit_mm_attribs
	({
		'NAME'          => 'DBD::Redbase',
		'VERSION_FROM'  => 'Redbase.pm', # finds $VERSION
		'PREREQ_PM'     => {
		                         Unicode::String => 2.06,
								 Bit::Vector => 6.1,
								 Bit::Vector::Overload => 6.1
						   }, # e.g., Module::Name => 1.1
		'INC'           => $DBI_INC_DIR,
		'dist'          => {
			                	'SUFFIX'   => '.gz',
								'COMPRESS' => 'gzip -9vf'
		                   },

		($] >= 5.005 ?    ## Add these new keywords supported since 5.005
		( 'AUTHOR'      => 'Bungisoft, Inc. <support@bungisoft.com>') : ())
	})
);

package MY;

sub postamble
{
	return main::dbd_postamble(@_);
}

sub libscan
{
	my($self, $path) = @_;
	($path =~ /\~$/) ? undef : $path;
}
