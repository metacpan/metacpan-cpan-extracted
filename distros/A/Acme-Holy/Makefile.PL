# $Id: Makefile.PL,v 1.2 2003/06/16 02:03:40 ian Exp $

# Makefile.PL for Acme::Holy
#
# Author:        I. Brayshaw <ian>onemore.org>
# Revision:      $Revision: 1.2 $
# Last modified: $Date: 2003/06/16 02:03:40 $

use 5.000;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Acme::Holy'                            ,
    'VERSION_FROM' => 'Holy.pm'                               ,
    'PREREQ_PM'    => { 'Test::More'      => 0 ,
	                    'Test::Exception' => 0 }              ,
    ($] >= 5.005 ?
      ( AUTHOR     => 'Ian Brayshaw <ian@onemore.org>') : ()) ,
    'LIBS'         => ['']                                    ,
    'DEFINE'       => ''                                      ,
    'INC'          => '-I.'
);
