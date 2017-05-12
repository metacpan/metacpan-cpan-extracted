#!perl

require 5.008001;

use strict;
use warnings;

use lib 'inc';

use Module::Build;
use MyBuilder;

my $build = MyBuilder->new(
  module_name => 'Data::Object::AutoWrap',
  dist_author => 'Andy Armstrong <andy.armstrong@messagesystems.com>',
  dist_version_from => 'lib/Data/Object/AutoWrap.pm',
  requires          => {
    'Scalar::Util' => 0,
    'Test::More'   => 0,
  },
  add_to_cleanup     => [ 'Data-Object-AutoWrap-*' ],
  sign               => 1,
  license            => 'perl',
);

$build->create_build_script;

# vim:ts=4:sw=4:et:ft=perl:
