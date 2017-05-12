use ExtUtils::MakeMaker;

WriteMakefile
(
	'NAME'		=> 'Apache::VimColor',
	'AUTHOR'	=> 'Florian Forster <octo@verplant.org>',
	'VERSION_FROM'	=> 'VimColor.pm',
	'PREREQ_PM'	=>
	{
		'Apache::Const'		=> 0,
		'Apache::RequestRec'	=> 0,
		'Apache::RequestIO'	=> 0,
		'Apache::RequestUtil'	=> 0,
		'Apache::Response'	=> 0,
		'Apache::Log'		=> 0,
		'Apache::Server'	=> 0,
		'File::Basename'	=> 0,
		'Text::VimColor'	=> 0
	}
);
