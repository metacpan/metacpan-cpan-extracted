#
# This file is part of Config-Model-Approx
#
# This software is Copyright (c) 2015-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
#    Copyright (c) 2009-2012 Dominique Dumont.
#
#    This file is part of Config-Model-Approx.
#
#    Config-Model is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Model is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
#    02110-1301 USA

use Module::Build;
use Data::Dumper ;

use warnings FATAL => qw(all) ;
use strict ;

require 5.010;

my %appli_files = map { ( $_, $_ ) } glob("lib/Config/Model/*.d/*");

# check that pod docs are up-to-date this is redundant with work done by
# dzil. But this enable to re-build the docs downstream.
# Use $^X in there as requested in 
# https://rt.cpan.org/Public/Bug/Display.html?id=74891
my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );

sub ACTION_build {
    my $self = shift;
    # below requires Config::Model 2.026
    system ($^X, '-MConfig::Model::Utils::GenClassPod', '-e','gen_class_pod();') == 0
                    or die "gen-class-pod failed: $?";
    $self->SUPER::ACTION_build;
}
SUBCLASS

my $build = $class->new
  (
   module_name   => 'Config::Model::Approx',
   license       => 'lgpl',
   dist_author   => "Dominique Dumont (ddumont at cpan dot org)",
   dist_abstract => "Approx configuration files graphical editor",
   appli_files => \%appli_files ,
 
  'build_requires' => {
    'Config::Model::Tester' => '4.001',
    'Config::Model::Tester::Setup' => '0',
    'Module::Build' => '0.34',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.34'
  },
  'recommends' => {
    'App::Cme' => '0',
    'Config::Model::TkUI' => '0'
  },
  'requires' => {
    'Carp' => '0',
    'Config::Model' => '2.123',
    'Config::Model::Backend::Any' => '0',
    'File::Copy' => '0',
    'File::Path' => '0',
    'Log::Log4perl' => '0',
    'Mouse' => '0',
    'perl' => '5.010'
  },

   add_to_cleanup => [qw/wr_root/] ,
  );


$build->add_build_element('pl');
$build->add_build_element('appli');

$build->create_build_script;
