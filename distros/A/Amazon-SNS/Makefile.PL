use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'Amazon::SNS',
	VERSION_FROM	=> 'lib/Amazon/SNS.pm',
	ABSTRACT	=> 'Amazon Simple Notification Service made simpler',
	AUTHOR		=> 'Alessandro Zummo <a.zummo@towertech.it>',
	LICENSE		=> 'GPLv2',
	PREREQ_PM	=> {
				'LWP::UserAgent'	=> 0,
				'XML::Simple'		=> 0,
				'Class::Accessor::Fast'	=> 0,
				'URI::Escape'		=> 0,
				'JSON'			=> 0,
			},			
);

