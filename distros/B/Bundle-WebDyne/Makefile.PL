#  Makefile.PL
#
package Bundle::WebDyne;


#  Compiler Pragma
#
use 5.006;
use strict  qw(vars);


#  External Modules
#
use ExtUtils::MakeMaker;
use File::Spec;
use IO::File;


#  Get MakeMaker version - from Test::Simple Makefile.PL
#
my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}


#  All done, init finished
#
#------------------------------------------------------------------------------


#  Create the Makefile params, save in hash
#
my $prereq_hr;
my %makefile=(

    NAME				    =>  __PACKAGE__,
    VERSION_FROM			    =>  File::Spec->catfile(

	'lib',
	split(/::/, __PACKAGE__),
	'VERSION.pm'

       ),

    'dist'				    =>  {

	COMPRESS			    =>  'gzip -9f',
	SUFFIX				    =>  '.gz'

       },

    'depend'				    =>  {

	Makefile			    =>  '$(VERSION_FROM)'

       },

    'macro'				    =>  {

        COPYRIGHT			    =>  'Copyright (C) 2006-2010 Andrew Speer, All rights reserved',
	LICENSE				    =>  'GPL: GNU General Public License',

       },

    ($] <  5.005 ? () : (
    
        AUTHOR				    =>  'Andrew Speer <andrew@webdyne.org>',
        
    )),

    ($mm_ver < 6.31 ? () : (

        LICENSE                             =>  'gpl',

    )),
    
    ($mm_ver <= 6.45 ? () : (
        
        META_MERGE => { resources => {
            
            homepage                        =>  'http://webdyne.org',
            license                         =>  'http://www.gnu.org/licenses/gpl.html'
            
        }}
    )),

   );


WriteMakefile(%makefile);

package MY;

sub constants {


    #  Add license file, other support files here
    #
    my $mm_or=shift();
    $mm_or->{'PM'}{'LICENSE'}='$(INST_LIBDIR)/$(BASEEXT)/LICENSE';
    $mm_or->SUPER::constants;

};


