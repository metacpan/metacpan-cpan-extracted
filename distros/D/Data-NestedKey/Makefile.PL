use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Data::NestedKey',
  VERSION_FROM => 'lib/Data/NestedKey.pm',                                     # Pull version from module
  ABSTRACT     => 'Object-oriented handling of deeply nested hash structures',
  AUTHOR       => 'Rob Lauer <rclauer@gmail.com>',
  LICENSE      => 'perl',
  PREREQ_PM    => {
    'Scalar::Util' => 0,
    'List::Util'   => 0,
    'Carp'         => 0,
    'JSON'         => 0,
    'YAML'         => 0,
    'Storable'     => 0,
  },
  TEST_REQUIRES => { 'Test::More' => 0, },
  META_MERGE    => { resources    => { repository => 'https://github.com/rlauer6/Data-NestedKey', }, },
);

1;
