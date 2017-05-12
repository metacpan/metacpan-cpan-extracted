
##--------------------------------------------------------------------------
##
##  Copyright (c) 2001 Gerald Richter / ecos gmbh www.ecos.de
##
##  You may distribute under the terms of either the GNU General Public 
##  License or the Artistic License, as specified in the Perl README file.
## 
##  THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED 
##  WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF 
##  MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
##
##  $Id: Makefile.PL,v 1.2 2001/09/14 05:41:13 richter Exp $
##
##   Building Makefile for Apache::ImageMagick
##
##--------------------------------------------------------------------------


use ExtUtils::MakeMaker;


WriteMakefile
    (
    'NAME'	=> 'Apache::ImageMagick',
    'VERSION_FROM' => 'ImageMagick.pm', # finds $VERSION
    'C' => [],
    );
