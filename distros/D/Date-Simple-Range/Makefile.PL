use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'Date::Simple::Range',
	VERSION_FROM	=> 'lib/Date/Simple/Range.pm',
	ABSTRACT_FROM	=> 'lib/Date/Simple/Range.pm',
	AUTHOR		=> 'Alessandro Zummo <a.zummo@towertech.it>',
	'LICENSE'	=> 'GPLv2',
	PREREQ_PM	=> {
				'Date::Simple'		=> 0,
				'Class::Accessor'	=> 0,
				'Time::Seconds'		=> 0,
			},			
);
