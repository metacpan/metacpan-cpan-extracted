
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'CAD::Format::STL',
  license             => 'perl',
  dist_version_from   => 'lib/CAD/Format/STL.pm',
  requires => {
    'Class::Accessor::Classy' => 'v0.1.3',
  },
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(CAD-Format-STL-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=CAD-Format-STL',
      #MailingList => 'mailto:...',
      repository =>
        'http://svn.scratchcomputing.com/CAD-Format-STL/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
