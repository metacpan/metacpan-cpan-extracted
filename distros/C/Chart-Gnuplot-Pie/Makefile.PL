use ExtUtils::MakeMaker;

WriteMakefile(
	AUTHOR        => 'Ka-Wai Mak',
	NAME          => 'Chart::Gnuplot::Pie',
	VERSION_FROM  => 'lib/Chart/Gnuplot/Pie.pm',
	ABSTRACT_FROM => "lib/Chart/Gnuplot/Pie.pm",
	PREREQ_PM     => { Chart::Gnuplot => 0.20 },
	dist          => {
		SUFFIX   => '.gz',
		COMPRESS => 'gzip -f'
	},

    ($ExtUtils::MakeMaker::VERSION > 6.48)? (LICENSE => "perl"): (),
);
