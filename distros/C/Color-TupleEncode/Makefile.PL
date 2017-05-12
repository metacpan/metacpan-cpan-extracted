use strict;
require 5.6.0;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME                => 'Color::TupleEncode',
	      AUTHOR              => q{Martin Krzywinski <martin.krzywinski@gmail.com>},
	      VERSION_FROM        => 'lib/Color/TupleEncode.pm',
	      ABSTRACT_FROM       => 'lib/Color/TupleEncode.pm',
	      ($ExtUtils::MakeMaker::VERSION >= 6.3002
	       ? ('LICENSE'=> 'perl')
	       : ()),
	      PL_FILES            => {},
	      PREREQ_PM => {
			    'Config::General' => 0,
			    'Carp' => 0,
			    'Cwd' => 0,
			    'File::Basename' => 0,
			    'FindBin' => 0,
			    'Getopt::Long' => 0,
			    'Graphics::ColorObject' => 0,
			    'Math::Round' => 0,
			    'Math::VecStat' => 0,
			    'parent' => 0,
			    'Pod::Usage' => 0,
			    'Test::More' => 0,
			    'Readonly' => 0,
			   },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'Color-TupleEncode-*' },
	     );
