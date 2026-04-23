#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2026 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use Module::Build;

use warnings FATAL => qw(all) ;
use strict ;

require 5.010;

# check that pod docs are up-to-date this is redundant with work done by
# dzil. But this enable to re-build the docs downstream.
# Use $^X in there as requested in 
# https://rt.cpan.org/Public/Bug/Display.html?id=74891
my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );

sub ACTION_build {
    my $self = shift;
    # below requires Config::Model 2.028
    system ($^X, '-MConfig::Model::Utils::GenClassPod', '-e','gen_class_pod("Itself::Model");') == 0
                    or die "gen-class-pod failed: $?";
    $self->SUPER::ACTION_build;
}
SUBCLASS

my $build = $class->new
  (
   module_name   => 'Config::Model::Itself',
   license       => 'lgpl',
   dist_author   => "Dominique Dumont (ddumont at cpan dot org)",
   dist_abstract => "Graphical editor of configuration models",

  'build_requires' => {
    'App::Cmd::Tester' => '0',
    'App::Cme' => '1.002',
    'Config::Model::Tester::Setup' => '0',
    'English' => '0',
    'File::Copy::Recursive' => '0',
    'File::Spec' => '0',
    'Getopt::Long' => '0',
    'Module::Build' => '0.34',
    'Test::Differences' => '0',
    'Test::Exception' => '0',
    'Test::File::Contents' => '0',
    'Test::Memory::Cycle' => '0',
    'Test::More' => '0',
    'Test::Perl::Critic' => '0',
    'Test::Pod' => '1.00',
    'Text::Diff' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.34'
  },
  'requires' => {
    'App::Cme' => '1.002',
    'App::Cme::Common' => '0',
    'Carp' => '0',
    'Config::Model' => '2.157',
    'Config::Model::TkUI' => '1.381',
    'Config::Model::Value' => '0',
    'Data::Compare' => '0',
    'Data::Dumper' => '0',
    'IO::File' => '0',
    'Log::Log4perl' => '1.11',
    'Mouse' => '0',
    'Mouse::Util::TypeConstraints' => '0',
    'Path::Tiny' => '0.125',
    'Pod::POM' => '0',
    'Scalar::Util' => '0',
    'Tk' => '0',
    'YAML::PP' => '0',
    'base' => '0',
    'feature' => '0',
    'lib' => '0',
    'perl' => 'v5.20.0',
    'strict' => '0',
    'warnings' => '0'
  },

   add_to_cleanup => [qw/wr_test wr_root/] ,
  );


$build->add_build_element('pl');

$build->create_build_script;
