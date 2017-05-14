#!/usr/bin/perl -w
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME			=> 'Acme::Intraweb',
	VERSION_FROM	=> 'lib/Acme/Intraweb.pm',          # finds $VERSION
    AUTHOR          => 'Jos Boumans (kane@cpan.org)',
    PREREQ_PM       => { CPANPLUS => '0.036' }
);