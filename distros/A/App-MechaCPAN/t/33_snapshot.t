use strict;
use FindBin;
use Test::More;
use File::Temp qw/tempdir tempfile/;
use File::Spec;
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

subtest 'bad snapshot' => sub
{
  chdir $pwd;

  my $tmpdir = tempdir(
    TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX",
    CLEANUP => 1,
  );

  chdir $tmpdir;
  my $dir = cwd;

  my ( $fh, $cpanfile ) = tempfile( "cpanfile.XXXXXXXX", DIR => $tmpdir );

  $fh->say("not a carton snapshot\nrest of content\n");

  local $@;
  my $result = eval { App::MechaCPAN::Deploy::parse_snapshot($cpanfile) };
  my $err = $@;

  is($result, undef, 'parse_snapshot produces error with a bad snapshot');
  like($err, qr/carton\s+snapshot/xms, 'Error is about carton snapshot');
};

subtest 'empty snapshot' => sub
{
  chdir $pwd;

  my $tmpdir = tempdir(
    TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX",
    CLEANUP => 1,
  );

  chdir $tmpdir;
  my $dir = cwd;

  my ( $fh, $cpanfile ) = tempfile( "cpanfile.XXXXXXXX", DIR => $tmpdir );

  local $@;
  my $result = eval { App::MechaCPAN::Deploy::parse_snapshot($cpanfile) };
  my $err = $@;

  is($result, undef, 'parse_snapshot produces error with a bad snapshot');
  like($err, qr/carton\s+snapshot/xms, 'Error is about carton snapshot');
};

done_testing;
