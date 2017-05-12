#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Apache::AntiSpam::JavaScript',
    'AUTHOR'            => 'Alex Pleiner <alex@zeitform.de>',
    'ABSTRACT'          => 'Encodes mailto: E-mail addresses with JavaScript',
    'VERSION_FROM'	=> 'JavaScript.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    Apache::Constants => 1.00,
                            Apache::File =>  1.00 ,
                           },
);
