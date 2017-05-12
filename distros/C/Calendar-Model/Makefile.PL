use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Calendar::Model',
    AUTHOR           => q{Aaron Trevena <teejay@cpan.org>},
    VERSION_FROM     => 'lib/Calendar/Model.pm',
    ABSTRACT_FROM    => 'lib/Calendar/Model.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	DateTime => 0,
	Moose => 2,
	'MooseX::Role::Pluggable' => 0.02,
	'Calendar::List' => 0.26,
	'Date::Holidays' => 0.15,
	'I18N::Langinfo' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Calendar-Model-*' },
   META_MERGE => {
     resources => {
       repository => 'https://github.com/hashbangperl/perl-calendar-model',
    },
   },
   ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'  => 'perl', ) : ()),


);
