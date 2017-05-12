
# -*- perl -*-

use DBI 1.03;
use DBI::DBD;
use ExtUtils::MakeMaker;

WriteMakefile
    dbd_edit_mm_attribs( { 'NAME'         => 'DBD::Yaswi',
			   'VERSION_FROM' => 'Yaswi.pm',
			   'INC'          => $DBI_INC_DIR },
			 {} );

sub postamble { return main::dbd_postamble(@_); }
