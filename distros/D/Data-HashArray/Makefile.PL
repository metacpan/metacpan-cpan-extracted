# $Id: Makefile.PL,v 1.1 2006/11/11 12:00:38 ayhan Exp $
#
use utf8;
use ExtUtils::MakeMaker;

use v5.8.1;  # refuse to compile on earlier

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	
    NAME          	=> 'Data::HashArray',
    VERSION_FROM	=> 'lib/Data/HashArray.pm',    
    ABSTRACT   		=> 'An array class of hashes that has magical properties via overloading and AUTOLOAD.',    
    DISTNAME      	=> 'Data-HashArray',
    LICENSE			=> 'perl',
    AUTHOR        	=> 'Ayhan Ulusoy <dev@ulusoy.name>',
    EXE_FILES     	=> [],
    
    PREREQ_PM	    =>  {
    			'Carp'							=> 0,
      			'Data::Dumper'					=> 0,
    			'Scalar::Util'					=> 0,
                'Test::More'  					=> 0,
                 },
	    

    clean        	=> { FILES =>"*.bak *~ *.old *.orig */*.bak */*~ */*.old */*.orig */*/*.bak */*/*~ */*/*.old */*/*.orig */*/*/*.bak */*/*/*~ */*/*/*.old */*/*/*.orig"}, 	

    
);



# =====================================================================

package MY;

sub libscan {
    my($self, $path) = @_;
    
    if 	  ($path =~ /(\~|\.bak|\.old|\.orig)$/) 	{	return undef;	}    # Backups, old files
    elsif ($path =~ /\.(\#|swp)$/) 					{	return undef;	}    # Temporaries & swap files.
    elsif ( ($path =~ /\b(RCS|CVS)\b/) 	||
    		($path =~ /\B\.svn\b/) 	   	||
    		($path =~ /,v$/)
    	)											{	return undef;	}    # CVS files
    
    else 											{	return $path;	}
}


1;



         
         
         
         

