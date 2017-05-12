
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'ApacheLog::Parser',
  license             => 'perl',
  dist_version_from   => 'lib/ApacheLog/Parser.pm',
  requires => {
    'Class::Accessor::Classy' => 'v0.9.0',
    'File::Fu'                => 'v0.0.1',
    'Getopt::Helpful'         => '0.04',
    'Date::Piece'             => 'v0.0.1',
    'IPC::Run'                => 0,
    'Digest::MD5'             => 0,
    'YAML'                    => 0,
  },
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(ApacheLog-Parser-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=ApacheLog-Parser',
      #MailingList => 'mailto:...',
      repository =>
        'http://scratchcomputing.com/svn/ApacheLog-Parser/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
