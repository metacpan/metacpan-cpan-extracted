use strict;
use warnings;
use ExtUtils::MakeMaker 6.30;
use File::Find;

my @tests;
find( sub { push @tests, $File::Find::name if /\.t$/ }, 't/');

WriteMakefile(
    NAME                => 'Dancer::Plugin::DynamicConfig',
    AUTHOR              => q{Kurt Starsinic <kstarsinic@gmail.com>},
    ABSTRACT            => 'Dancer plugin for reading dynamically-updated configuration files',
    VERSION_FROM        => 'lib/Dancer/Plugin/DynamicConfig.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
     ? ('LICENSE'=> 'perl')
     : ()),
    PL_FILES            => {},
    BUILD_REQUIRES => {
      'Dancer'                => 0,
      'Dancer::Config'        => 0,
      'Dancer::FileUtils'     => 0,
      'Dancer::ModuleLoader'  => 0,
      'Dancer::Plugin'        => 0,
      'Dancer::Test'          => 0,
      'Encode'                => 0,
      'File::Temp'            => 0,
      'JSON::XS'              => 0,
      'Test::Most'            => 0,
      'Time::HiRes'           => 0,
      'Try::Tiny'             => 0,
      'YAML'                  => 0,
    },
    META_MERGE => {
      resources => {
        bugtracker  => 'https://github.com/kstarsinic/dancer-plugin-dynamic-config/issues',
        homepage    => 'https://github.com/kstarsinic/dancer-plugin-dynamic-config',
        repository  => 'git://github.com/kstarsinic/dancer-plugin-dynamic-config.git',
      },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-*' },
    test                => { TESTS => "-It/unit/lib @tests" },
    );
