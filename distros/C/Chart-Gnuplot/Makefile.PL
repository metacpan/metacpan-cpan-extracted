use ExtUtils::MakeMaker;

WriteMakefile(
	AUTHOR        => 'Ka-Wai Mak',
	NAME          => 'Chart::Gnuplot',
	VERSION_FROM  => 'lib/Chart/Gnuplot.pm',
	ABSTRACT_FROM => "lib/Chart/Gnuplot.pm",
	PREREQ_PM     => {
        Carp       => 1.04,
        File::Copy => 2.08,
        File::Temp => 0.14,
        Storable   => 2.15,
    },
	dist          => {
		SUFFIX   => '.gz',
		COMPRESS => 'gzip -f'
	},

    ($ExtUtils::MakeMaker::VERSION > 6.48)? (LICENSE => "perl"): (),
);
