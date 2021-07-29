#! perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Properties',
    AUTHOR              => 'Johan Vromans <jvromans@squirrel.nl>',
    VERSION_FROM        => 'lib/Data/Properties.pm',
    ABSTRACT_FROM       => 'lib/Data/Properties.pm',
    LICENSE		=> 'perl_5',
    PL_FILES            => {},
    MIN_PERL_VERSION	=> '5.010001',
    PREREQ_PM => {
        'ExtUtils::MakeMaker' => 6.46, # for META_MERGE, LICENSE
        'Test::More' => 0,
	'File::LoadLines' => 1.02,
	'String::Interpolate::Named' => 1.01,
	'Text::ParseWords' => 0,
    },
    META_MERGE => {
      resources    => {
        repository => {
          type => 'git',
	   web  => 'https://github.com/sciurius/perl-Data-Properties',
	   url  => 'https://github.com/sciurius/perl-Data-Properties.git',
	},
	bugtracker => {
	  web => "https://github.com/sciurius/perl-Data-Properties/issues",
	},
      },
      'meta-spec' => {
        version => '2',
	url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
      },
    },
);
