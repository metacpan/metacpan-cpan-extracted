use strict;
use FindBin;
use File::Copy;
use Test::More;
use Cwd qw/cwd/;

require q[./t/helper.pm];

my $pwd = cwd;

my $cpanfile      = "$FindBin::Bin/../test_dists/DeploySnapshot/cpanfile";
my $snapshot      = "$cpanfile.snapshot";
my $cpanfile_info = App::MechaCPAN::Deploy::parse_snapshot($snapshot);

my $output = {
  'Try-Tiny-0.24' => {
    'pathname'     => 'E/ET/ETHER/Try-Tiny-0.24.tar.gz',
    'provides'     => { 'Try::Tiny' => '0.24' },
    'requirements' => {
      'Carp'                => '0',
      'warnings'            => '0',
      'constant'            => '0',
      'Exporter'            => '5.57',
      'ExtUtils::MakeMaker' => '0',
      'perl'                => '5.006',
      'strict'              => '0'
    }
  }
};

is_deeply(
  $cpanfile_info, $output,
  "parse_snapshot produces the expected requirements"
);

done_testing;
