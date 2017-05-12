use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::Interchange6',
    AUTHOR              => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM        => 'lib/Dancer/Plugin/Interchange6.pm',
    ABSTRACT            => 'Dancer Plugin for Interchange6 Open Source Shop Machine (DEPRECATED)',
    ($ExtUtils::MakeMaker::VERSION >= 6.47
      ? ('LICENSE'=> 'perl')
      : ()),
    MIN_PERL_VERSION    => '5.010000',
    PL_FILES            => {},
    EXE_FILES           => ['bin/interchange6-expire-sessions'],
    BUILD_REQUIRES      => {
                            'Test::More' => 0,
                            'Test::Deep' => 0,
                            'Test::Exception' => 0,
                            'DBICx::TestDatabase' => 0,
                            'Test::Database' => 0,
                            'Test::Roo' => 1.004,
                            'Test::WWW::Mechanize::PSGI' => '0.35',
                      },
    PREREQ_PM => {
                  'YAML'       => 0,
                  'Interchange6::Schema'     => '0.110',
                  'Interchange6' => '0.120',
                  'Dancer'     => 1.3098,
                  'Dancer::Session::DBIC' => '0.004',
                  'Dancer::Plugin::DBIC' => 0,
                  'Dancer::Plugin::Auth::Extensible' => 0,
                  'Dancer::Plugin::Auth::Extensible::Provider::DBIC' => 0,
                  'Business::OnlinePayment' => 3.02,
                  'Module::Runtime' => 0,
                  'MooseX::CoverableModifiers' => 0,
                  'namespace::clean' => 0,
                  # Net::HTTPS::Any is required by Business::OnlinePayment but
                  # versions before 0.11 have a habit of failing to install
                  # so add this dep to make installing DPIC6 more reliable
                  'Net::HTTPS::Any' => '0.11', # 
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-Interchange6-*' },
    test                => { TESTS => join( ' ', (glob( 't/*.t'), glob('t/*/*.t')))},
    META_MERGE        => {
        x_deprecated => 1,
        resources => {
            repository  => 'https://github.com/interchange/Dancer-Plugin-Interchange6.git',
            bugtracker => 'https://github.com/interchange/Dancer-Plugin-Interchange6/issues',
            IRC => 'irc://irc.freenode.net/#interchange',
        },
    },
);
