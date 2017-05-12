use strict;
use warnings;

use lib 'inc';

use Module::Build;
use MyBuilder;

my $build = MyBuilder->new(
  module_name       => 'Crypt::PerfectPaperPasswords',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/Crypt/PerfectPaperPasswords.pm',
  requires          => {
    'Crypt::Rijndael' => 0,
    'Digest::SHA256'  => 0,
    'Getopt::Long'    => 0,
    'Pod::Usage'      => 0,
    'Scalar::Util'    => 0,
    'Test::More'      => 0,
    'Time::HiRes'     => 0
  },
  script_files   => 'bin/pppp',
  add_to_cleanup => ['Crypt-PerfectPaperPasswords-*'],
  license        => 'perl',
);

$build->create_build_script;
