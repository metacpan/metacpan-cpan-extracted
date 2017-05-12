#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Apache::AntiSpam::SpamTrap',
    'AUTHOR'            => 'Alex Pleiner <alex@zeitform.de>',
    'ABSTRACT'          => 'Add SpamTrap suffix to local-part in Email',
    'VERSION_FROM'	=> 'SpamTrap.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    Apache::AntiSpam => 0.05,
			    Crypt::Blowfish => 2.00,
                           },
);
