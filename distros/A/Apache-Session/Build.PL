use strict;
use Module::Build;
#created by eumm-migrate.pl

print << 'EOT';

*** REQUEST ***
Please use Test::Reporter to report test results - it's the only way to measure
popularity of distribution.

Or you can add it to stack (means that you use it) on Ohloh: https://www.ohloh.net/p/Apache-Session

EOT

if ($]<5.006) {
  print << 'EOT1';
If you really use perl older than 5.6 - write to alexchorny[AT]gmail.com
and tell me what version do you use, and why.
EOT1
  Module::Build->prompt('continue','y');
}


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
