use utf8;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyEvent::CallbackStack',
    AUTHOR              => q{BlueT - Matthew Lien - 練喆明 <BlueT@BlueT.org>},
    VERSION_FROM        => 'lib/AnyEvent/CallbackStack.pm',
    ABSTRACT_FROM       => 'lib/AnyEvent/CallbackStack.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    BUILD_REQUIRES => {
	'Test::More'		=> 0,
	'Test::Simple'		=> 0,
    },
    PREREQ_PM => {
        'feature'		=> 0,
	'AnyEvent'		=> 0,
	'common::sense'		=> 0,
	'Data::Dumper::Simple'	=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AnyEvent-CallbackStack-*' },
);
