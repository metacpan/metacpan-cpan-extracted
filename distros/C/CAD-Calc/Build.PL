
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'CAD::Calc',
  license             => 'perl',
  dist_version_from   => 'lib/CAD/Calc.pm',
  requires => {
    'Test::More'       => 0,
    'Math::Vec'        => 0.03,
    'Math::Round::Var' => 0.02,
    'Math::Complex'    => 0,
    'Math::BigFloat'   => 0,
  },
  recommends => {
    'Math::Geometry::Planar::Offset' => 1.03_01
  },
  add_to_cleanup      => [ qw(CAD-Calc-* META.yml)],
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=CAD-Calc',
      #MailingList => 'mailto:...',
      repository =>
        'http://scratchcomputing.com/svn/CAD-Calc/trunk',
    }
  },
);

$builder->create_build_script();
