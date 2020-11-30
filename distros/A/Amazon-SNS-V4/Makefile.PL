use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'Amazon::SNS::V4',
	VERSION_FROM	=> 'lib/Amazon/SNS/V4.pm',
	ABSTRACT	=> 'Amazon Simple Notification Service, V4 Signatures', 
	AUTHOR		=> 'James Wright <jwright@cpan.org>',
	LICENSE		=> 'GPLv2',
	PREREQ_PM	=> {
				'LWP::UserAgent'	=> 0,
				'XML::Simple'		=> 0,
				'Class::Accessor::Fast'	=> 0,
				'URI::Escape'		=> 0,
				'JSON'			=> 0,
				'AWS::Signature4' => 0,
			},			
);

