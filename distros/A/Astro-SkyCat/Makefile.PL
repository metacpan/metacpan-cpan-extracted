use ExtUtils::MakeMaker;

my $CAT_DIR = "/home/timj/data/tmp/catlib-3.7.1";

WriteMakefile(
	      'NAME'      => 'Astro::SkyCat',
	      'VERSION_FROM'   => 'SkyCat.pm',
	      'CC' => 'g++',
	      'LD' => 'g++',
	      'LIBS'      => [
			      "-L${CAT_DIR}/cat/astrocat/lib -lastrocat -L${CAT_DIR}/tclutil/util/lib -lutil -L${CAT_DIR}/astrotcl/wcslib/lib -lwcslib -L${CAT_DIR}/astrotcl/compress/lib -lcompress",
			     ],
              'PREREQ_PM' => {
			      'Test' => undef,
			     },
	      'INC'       => "-I${CAT_DIR}/cat/astrocat/include -I${CAT_DIR}/cat/ccat/include -I${CAT_DIR}/astrotcl/wcslib/include -I${CAT_DIR}/tclutil/util/include",
	      'dist'      => { COMPRESS => "gzip -9f"},
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM => 'SkyCat.pm',
		AUTHOR     => 'Tim Jenness <t.jenness@jach.hawaii.edu>') : ()),
	     );

