#
# Makefile.PL - build file for DBM::Tree::Manager
#
# Copyright (c) 2007-2015 T. v.Dein <tom |AT| cpan.org>.
# All Rights Reserved. Std. disclaimer applies.
# Artistic License, same as perl itself. Have fun.
#

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME	   => 'DBM::Deep::Manager',
	      VERSION_FROM => 'Manager.pm',
	      'EXE_FILES'    => [ 'bin/dbmdeep' ],
              ABSTRACT     => 'Maintain DBM::Deep databases interactively',
              LICENSE      => 'perl',
              AUTHOR       => 'Thomas v.Dein <tlinden@cpan.org>',
	      clean        => { FILES => '*~ */*~' },
	      PREREQ_PM    => { 
			       'DBM::Deep' => 2.0,
			       'YAML'      => 0,
			       'Data::Interactive::Inspect' => 0,
              },
	      dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      test         => { TESTS => 't/*.t' },
              'META_MERGE' => {
                               resources => {
                                             repository => 'https://github.com/TLINDEN/dbmdeep',
                                            },
                              },

);

