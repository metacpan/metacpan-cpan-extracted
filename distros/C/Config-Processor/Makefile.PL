use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME               => 'Config::Processor',
  VERSION_FROM       => 'lib/Config/Processor.pm',
  PREREQ_PM          => {
    'File::Spec'       => '0',
    'YAML::XS'         => '0.41',
    'Cpanel::JSON::XS' => '3.0104',
    'Hash::Merge'      => '0.200',
    'Scalar::Util'     => '0',
    'Carp'             => '0',
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.64',
  },
  BUILD_REQUIRES => {
    'Test::More'  => 0.98,
    'Test::Fatal' => '0.013',
  },
  META_MERGE => {
    resources => {
      homepage   => 'https://github.com/iph0/Config-Processor',
      bugtracker => 'https://github.com/iph0/Config-Processor/issues',
      repository => 'https://github.com/iph0/Config-Processor',
      license    => 'http://dev.perl.org/licenses/',
    },
  },
  ABSTRACT_FROM => 'lib/Config/Processor.pm',
  AUTHOR        => 'Eugene Ponizovsky <ponizovsky@gmail.com>',
  LICENSE       => 'perl',
);
