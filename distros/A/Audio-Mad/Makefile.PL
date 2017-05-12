use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Audio::Mad',
	'VERSION_FROM'	=> 'Mad.pm',
	($] >= 5.005 ? (
		ABSTRACT_FROM => 'Mad.pm',
		AUTHOR        => 'Mark McConnell <mischke@cpan.org>'
	) : ()),
	'LIBS'		=> ['-lmad '],
	'MYEXTLIB'      => 'resample.o dither.o'
);

