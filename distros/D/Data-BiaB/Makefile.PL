#! perl

use strict;
use warnings;
use ExtUtils::MakeMaker '6.56';

WriteMakefile(
    NAME                => 'Data::BiaB',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION             => '0.11',
#    VERSION_FROM        => 'lib/Data/BiaB.pm',
    ABSTRACT_FROM       => 'lib/Data/BiaB.pm',
    PL_FILES            => {},
    MIN_PERL_VERSION	=> '5.010000',
    PREREQ_PM => {
        'Test::More' => 0,
	'Data::Hexify' => 0,
	'MIDI' => 0,
    },
    META_MERGE => {
	license          => "perl_5",
	resources        => {
	    repository   => {
		type => 'git',
		url  => 'git://github.com/sciurius/perl-Data-BiaB',
		web  => 'https://github.com/sciurius/perl-Data-BiaB',
	    },
	},
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-BiaB-*' },
);
