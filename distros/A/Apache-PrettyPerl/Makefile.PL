use ExtUtils::MakeMaker;

WriteMakefile
(
	NAME		=> 'Apache::PrettyPerl',
	VERSION_FROM	=> 'PrettyPerl.pm',
	PREREQ_PM	=>
	{
		'Apache::Const'		=> 0,
		'Apache::RequestRec'	=> 0,
		'Apache::RequestIO'	=> 0,
		'Apache::RequestUtil'	=> 0,
		'Apache::Response'	=> 0,
		'File::Basename'	=> 0
	}
);
