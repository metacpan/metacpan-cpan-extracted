use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  ('NAME'	   => 'BikePower',
   'VERSION_FROM' => 'BikePower.pm', # finds $VERSION
   'EXE_FILES'    => ['bikepwr', 'tkbikepwr'],
   'dist'      => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => '.gz',
		   'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
   # all of these are optional
   'PREREQ_PM' => {# 'Tk'             => 402.002,
		   # 'Data::Dumper'   => 2.08,
		   # 'Tk::Pod'        => 0,
		  },
   'ABSTRACT_FROM' => 'BikePower.pm',
   'AUTHOR' => 'Slaven Rezic (eserte@cs.tu-berlin.de)',
  );
