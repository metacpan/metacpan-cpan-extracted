use ExtUtils::MakeMaker;

$CC = 'g++';

%args = ('CCFLAGS' => '-Wall');

if($^O eq 'cygwin') {
  $args{'LDDLFLAGS'} = '-shared -L/usr/local/lib';
}

WriteMakefile('NAME'          => 'Algorithm::SVM',
	      'VERSION_FROM'  => 'lib/Algorithm/SVM.pm',
	      'PREREQ_PM'     => {},
	      ($] >= 5.005 ?
	       (ABSTRACT_FROM => 'lib/Algorithm/SVM.pm',
		AUTHOR        => 'Matthew Laird <matt@brinkman.mbb.sfu.ca>') : ()),
	      'OPTIMIZE'      => '-O3',  # segfaults with gcc 2.96 if lower (?)
	      'LIBS'          => '-lm',
	      'CC'            => $CC,
	      'LD'            => '$(CC)',
	      'OBJECT'        => 'SVM.o libsvm.o bindings.o',
	      'XSOPT'         => '-C++ -noprototypes',
              %args);
