use ExtUtils::MakeMaker;

WriteMakefile(
	AUTHOR          => 'Sun Bing (hoowa.sun@gmail.com)',
	NAME            => 'Asterisk::config',
	ABSTRACT        => 'The Asterisk config read and write module.',
	VERSION_FROM    => 'lib/Asterisk/config.pm',
	($ExtUtils::MakeMaker::VERSION >= 6.31
		? ( LICENSE => 'gpl' )
		: ()
	),
);
