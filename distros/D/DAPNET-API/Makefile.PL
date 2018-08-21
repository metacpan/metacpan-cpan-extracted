use ExtUtils::MakeMaker;

WriteMakefile
(
	'NAME'		=>	'DAPNET::API',
	'VERSION_FROM'	=>	'lib/DAPNET/API.pm',
	'PREREQ_PM'	=>	{
		'LWP::UserAgent'	=>	0,
		'JSON'			=>	0,
		'MIME::Base64'		=>	0
	}

);
