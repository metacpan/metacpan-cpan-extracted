use 5.016;
use strict;
use warnings;
use utf8;
use ExtUtils::MakeMaker;

my $GITHUB_URL = 'https://github.com/jhthorsen/docsis::configfile';

my %WriteMakefileArgs = (
  AUTHOR        => 'Jan Henning Thorsen <jhthorsen@cpan.org>',
  LICENSE       => 'artistic_2',
  NAME          => 'DOCSIS::ConfigFile',
  ABSTRACT_FROM => 'lib/DOCSIS/ConfigFile.pm',
  VERSION_FROM  => 'lib/DOCSIS/ConfigFile.pm',
  EXE_FILES     => [qw(script/docsis-configfile script/docsisious)],
  TEST_REQUIRES => {'Test::More' => '0.8'},
  PREREQ_PM     => {
    'Digest::HMAC_MD5' => '1.00',
    'Digest::MD5'      => '2.30',
    'Digest::SHA'      => '5.00',
    'Math::BigInt'     => '1.80',
    'YAML::PP'         => '0.03',
    'Socket'           => '1.50',
    'bytes'            => '1.00',
  },
  META_MERGE => {
    'dynamic_config' => 0,
    'meta-spec'      => {version   => 2},
    'no_index'       => {directory => [qw(examples t)]},
    'prereqs'        => {runtime   => {requires => {perl => '5.016'}}},
    'resources'      => {
      bugtracker => {web => "$GITHUB_URL/issues"},
      homepage   => $GITHUB_URL,
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {type => 'git', url => "$GITHUB_URL.git", web => $GITHUB_URL},
      x_IRC => {url => 'irc://irc.libera.chat/#convos', web => 'https://web.libera.chat/#convos'},
    },
    'x_contributors' => [],
  },
  test => {TESTS => (-e 'META.yml' ? 't/*.t' : 't/*.t xt/*.t')},
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.63_03') }) {
  my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES};
  @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

WriteMakefile(%WriteMakefileArgs);
