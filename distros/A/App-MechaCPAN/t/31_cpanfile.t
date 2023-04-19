use strict;
use FindBin;
use File::Copy;
use Test::More;
use Cwd qw/cwd/;

require q[./t/helper.pm];

my $pwd = cwd;

my $cpanfile      = "$FindBin::Bin/../test_dists/DeployCpanfile/cpanfile";
my $cpanfile_info = App::MechaCPAN::parse_cpanfile($cpanfile);

my $output = {
  'runtime' => {
    'requires' => {
      'Try::Tiny' => undef,
    },
  },
  'configure' => { 'requires' => { 'Test::More' => undef } },
  'perl' => '5.012000',
};

is_deeply(
  $cpanfile_info, $output,
  "parse_cpan produces the expected requirements"
);

done_testing;
