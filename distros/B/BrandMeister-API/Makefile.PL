use ExtUtils::MakeMaker;

WriteMakefile
(
	'NAME'		=>	'BrandMeister::API',
	'VERSION_FROM'	=>	'lib/BrandMeister/API.pm',
	'PREREQ_PM'	=>	{
		'LWP::UserAgent'	=>	0,
		'JSON'			=>	0,
		'MIME::Base64'		=>	0
	}

);
