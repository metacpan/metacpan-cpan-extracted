use strict;
use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME            => 'Cvs',
    DISTNAME        => 'Cvs',
    VERSION_FROM    => 'lib/Cvs.pm', # finds $VERSION
    PMLIBDIRS       => ['lib'],
    PREREQ_PM       => 
    {
	'IO::Pty'	  => '1.02',
        'IPC::Run'        => '0.74',
        'Class::Accessor' => '0.17',
        'FileHandle'      => '2.0',
        'File::Temp'      => '0.12',
        'Cwd'             => '2.04',
    },
    AUTHOR          => 'Olivier Poitrey <rs@rhapsodyk.net>',
);
