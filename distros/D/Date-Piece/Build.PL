
require 5.008;

use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Date::Piece',
  license             => 'perl',
  dist_version_from   => 'lib/Date/Piece.pm',
  requires => {
    perl           => '5.8.2',
    'Date::Simple' => 0,
    'Time::Piece'  => 0,
    'Time::Local', => 0,
  },
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(Date-Piece-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Piece',
      #MailingList => 'mailto:...',
      repository =>
        'http://svn.scratchcomputing.com/Date-Piece/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
