use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Data::Match',
    'VERSION_FROM'	=> 'Match.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
      'Data::Dumper'      => 0, # '2.102', 
      'Data::Compare'     => 0, # '0.02', 
      'String::Escape'    => 0, # '1998.1204'
      },
	      # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Match.pm', # retrieve abstract from module
       AUTHOR     => 'Kurt Stephens <kurtstephens@acm.org>') : ()),
);

# $Id: Makefile.PL,v 1.3 2002/04/22 06:36:58 stephens Exp $
