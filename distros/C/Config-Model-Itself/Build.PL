#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
#    Copyright (c) 2009-2013 Dominique Dumont.
#
#    This file is part of Config-Model-Itself.
#
#    Config-Model is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Model is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
#    02110-1301 USA

use Module::Build;

use warnings FATAL => qw(all) ;
use strict ;

require 5.010;

# my %appli_files = map { ( $_, $_ ) } glob("lib/Config/Model/*.d/*");

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
    system ($^X, '-MConfig::Model::Utils::GenClassPod', '-e','gen_class_pod();') == 0
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
   # model_files => \%model_files ,

  'build_requires' => {
    'App::Cmd::Tester' => '0',
    'App::Cme' => '1.002',
    'Config::Model' => '2.142',
    'Config::Model::Tester::Setup' => '0',
    'File::Copy::Recursive' => '0',
    'Getopt::Long' => '0',
    'Module::Build' => '0.34',
    'Test::Differences' => '0',
    'Test::Exception' => '0',
    'Test::File::Contents' => '0',
    'Test::Memory::Cycle' => '0',
    'Test::More' => '0',
    'Test::Pod' => '1.00',
    'Text::Diff' => '0',
    'perl' => '5.014'
  },
  'configure_requires' => {
    'Module::Build' => '0.34'
  },
  'requires' => {
    'App::Cme' => '1.002',
    'App::Cme::Common' => '0',
    'Carp' => '0',
    'Config::Model' => '2.142',
    'Config::Model::TkUI' => '1.370',
    'Config::Model::Value' => '0',
    'Data::Compare' => '0',
    'Data::Dumper' => '0',
    'File::Basename' => '0',
    'File::Find' => '0',
    'File::Path' => '0',
    'IO::File' => '0',
    'Log::Log4perl' => '1.11',
    'Mouse' => '0',
    'Mouse::Util::TypeConstraints' => '0',
    'Path::Tiny' => '0.062',
    'Pod::POM' => '0',
    'Scalar::Util' => '0',
    'Tk' => '0',
    'YAML::XS' => '0',
    'base' => '0',
    'lib' => '0',
    'perl' => '5.014',
    'strict' => '0',
    'warnings' => '0'
  },

   add_to_cleanup => [qw/wr_test wr_root/] ,
  );


$build->add_build_element('pl');
# $build->add_build_element('appli');

$build->create_build_script;
