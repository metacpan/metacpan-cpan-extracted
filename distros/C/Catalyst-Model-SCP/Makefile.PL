use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Catalyst::Model::SCP',
    AUTHOR           => q{Rakesh Kumar Shardiwal <rakesh.shardiwal@gmail.com>},
    VERSION_FROM     => 'lib/Catalyst/Model/SCP.pm',
    ABSTRACT_FROM    => 'lib/Catalyst/Model/SCP.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::WWW::Mechanize::Catalyst' => 0,
        'Catalyst' => 0,
        'Catalyst::Model' => 0,
        'Moose' => 0,
        'MooseX::Types::Moose' => 0,
        'Moose::Util::TypeConstraints' => 0,
        'File::Temp' => 0,
        'Net::SCP::Expect' => 0,
	'Expect' => '1.14',
	'Term::ReadPassword' => '0.01',
	'Net::IPv6Addr' => '0.2',
    },
    PREREQ_PM => {
        'Catalyst' => 0,
        'Catalyst::Model' => 0,
        'Moose' => 0,
        'MooseX::Types::Moose' => 0,
        'Moose::Util::TypeConstraints' => 0,
        'File::Temp' => 0,
        'Net::SCP::Expect' => 0,
	'Expect' => '1.14',
	'Term::ReadPassword' => '0.01',
	'Net::IPv6Addr' => '0.2',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Catalyst-Model-SCP-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/shardiwal/cpan-catalyst-model-SCP/issues'
            },
            homepage => 'http://www.catalystframework.org/',
            repository => {
                type => 'git',
                url => 'git@github.com:shardiwal/cpan-catalyst-model-SCP.git',
                web => 'https://github.com/shardiwal/cpan-catalyst-model-SCP'
            }
        }
    },
);
