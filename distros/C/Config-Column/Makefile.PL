use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> 'Config::Column',
	VERSION_FROM	=> 'lib/Config/Column.pm',
	ABSTRACT => 'Config::Column Simply packages config/log file IO divided by any delimiter.',
	PREREQ_PM		=> {},
	($] >= 5.005 ?	## Add these new keywords supported since 5.005
	  (AUTHOR	=> 'Narazaka (http://narazaka.net/)') : ()),
	( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE' => 'perl', ) : () ),
);
