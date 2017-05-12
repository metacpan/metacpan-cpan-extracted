#
# Makefile.PL - build file for Data::Interactive::Inspect
#
# Copyright (c) 2007-2014 T. v.Dein <tom |AT| cpan.org>.
# All Rights Reserved. Std. disclaimer applies.
# Artistic License, same as perl itself. Have fun.
#

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME	   => 'Data::Interactive::Inspect',
	      VERSION_FROM => 'Inspect.pm',
              ABSTRACT     => 'Inspect and manipulate perl data structures interactively',
              LICENSE      => 'perl',
              AUTHOR       => 'Thomas v.Dein <tlinden@cpan.org>',
	      clean        => { FILES => '*~ */*~' },
	      PREREQ_PM    => { 
			       'YAML'      => 0,
			       'File::Temp' => 0,
			       'Term::ReadLine' => 0,
              },
	      dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      test         => { TESTS => 't/*.t' },
              'META_MERGE' => {
                               resources => {
                                             repository => 'https://github.com/TLINDEN/Data-Interactive-Inspect',
                                            },
                              },

);

