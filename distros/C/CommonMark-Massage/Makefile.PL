#! perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CommonMark::Massage',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION_FROM        => 'lib/CommonMark/Massage.pm',
    ABSTRACT_FROM       => 'lib/CommonMark/Massage.pm',
    LICENSE		=> 'perl_5',
    PL_FILES            => {},
    MIN_PERL_VERSION	=> '5.010001',
    PREREQ_PM => {
	'CommonMark' => 0.29,
        'ExtUtils::MakeMaker' => 6.46, # for META_MERGE, LICENSE
        'Test::More' => 0,
    },
    META_MERGE => {
      resources    => {
        repository => {
          type => 'git',
	   web  => 'https://github.com/sciurius/perl-CommonMark-Massage',
	   url  => 'https://github.com/sciurius/perl-CommonMark-Massage.git',
	},
	bugtracker => {
	  web => "https://github.com/sciurius/perl-CommonMark-Massage/issues",
	},
      },
      'meta-spec' => {
        version => '2',
	url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
      },
    },
);
