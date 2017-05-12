use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Model::Filemaker',
    AUTHOR              => q{Michele Ongaro <micheleo@cpan.org>},
    VERSION_FROM        => 'lib/Catalyst/Model/Filemaker.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Model/Filemaker.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    
    PREREQ_PM => {
    'Test::More'    => 0,
    'Catalyst::Runtime'     => '5.80005',
    'Net::FileMaker::XML::ResultSet'       => 0,
    'Carp'      => 0,
    },

    MIN_PERL_VERSION => '5.008',

    META_MERGE => {
    resources => {
            repository => 'http://github.com/micheleo/Catalyst--Model--Filemaker'
    }
    },

    test            => { TESTS => join( ' ', (glob( 't/*.t'), glob('t/*/*.t'))) },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst::Model::Filemaker-*' },
);
