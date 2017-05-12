use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer2::Plugin::Interchange6',
    AUTHOR              => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM        => 'lib/Dancer2/Plugin/Interchange6.pm',
    ABSTRACT            => 'Dancer2 Plugin for Interchange6 Open Source Shop Machine',
    ($ExtUtils::MakeMaker::VERSION >= 6.47
      ? ('LICENSE'=> 'perl')
      : ()),
    MIN_PERL_VERSION    => '5.010000',
    PL_FILES            => {},
    EXE_FILES           => ['bin/interchange6-expire-sessions'],
    BUILD_REQUIRES      => {
                            'File::Temp' => 0,
                            'Module::Find' => 0,
                            'Test::More' => '0.94', # subtest
                            'Test::Deep' => 0,
                            'Test::Exception' => 0,
                            'Test::WWW::Mechanize::PSGI' => '0.35',
                      },
    PREREQ_PM => {
                  'JSON::MaybeXS' => '1.003003',
                  'YAML'       => 0,
                  'Interchange6::Schema'     => '0.110',
                  'Interchange6' => '0.120',
                  'Dancer2'     => '0.200000',
                  'Dancer2::Session::DBIC' => '0.102',
                  'Dancer2::Plugin::DBIC' => '0.0013',
                  'Dancer2::Plugin::Auth::Extensible' => '0.600',
                  'Dancer2::Plugin::Auth::Extensible::Provider::DBIC' => '0.600',
                  'Business::OnlinePayment' => 3.02,
                  'Module::Runtime' => 0,
                  'MooseX::CoverableModifiers' => 0,
                  'namespace::clean' => 0,
                  # Net::HTTPS::Any is required by Business::OnlinePayment but
                  # versions before 0.11 have a habit of failing to install
                  # so add this dep to make installing DPIC6 more reliable
                  'Net::HTTPS::Any' => '0.11', # 
                  'Scalar::Util' => 0, # weaken
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer2-Plugin-Interchange6-*' },
    test                => { TESTS => join( ' ', (glob( 't/*.t'), glob('t/*/*.t')))},
    META_MERGE        => {
        resources => {
            repository  => 'https://github.com/interchange/Dancer2-Plugin-Interchange6.git',
            bugtracker => 'https://github.com/interchange/Dancer2-Plugin-Interchange6/issues',
            IRC => 'irc://irc.freenode.net/#interchange',
        },
    },
);
