use strict;
use Module::Build;
#created by eumm-migrate.pl

my $build = Module::Build->new(
  'dist_abstract' => 'A persistence framework for session data',
  'license' => 'perl',
  'build_requires' => {
    'Test::More' => '0.47',
    'Test::Exception' => '0.15',
    'Test::Deep' => '0.082',
    ($ENV{TRAVIS}?('Test::Database'=>0, 'DBD::mysql'=>0, 'DBD::Pg' => 0,):()),
  },
  'dist_author' => 'Casey West <casey[at]geeknest.com>',
  'module_name' => 'Apache::Session',
  'meta_merge' => {
    'keywords' => [
      'CGI',
      'session',
      'web'
    ],
    'resources' => {
      'repository' => 'http://github.com/chorny/Apache-Session'
    }
  },
  'requires' => {
    'perl' => '5.005',
    'File::Temp' => 0,
    'Storable' => '0.6',
    'constant' => 0,
    'Digest::MD5' => 0,
    'IO::File' => 0,
  },
  'dist_version_from' => 'lib/Apache/Session.pm',
  'auto_configure_requires' => 0,
);

$build->create_build_script();
