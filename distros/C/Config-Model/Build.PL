#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
#    Copyright (c) 2005-2012 Dominique Dumont.
#
#    This file is part of Config-Model.
#
#    Config-Model is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public License as
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

use warnings FATAL => qw(all);
use strict;

require 5.010001 ;

print "\nIf you want to use the TermUI interface, you should install\n",
  "Term::ReadLine::Perl or Term::ReadLine::Gnu\n\n";

# check that pod docs are up-to-date this is redundant with work done by
# dzil. But this enable to re-build the docs downstream.
# Use $^X in there as requested in 
# https://rt.cpan.org/Public/Bug/Display.html?id=74891
my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );

sub ACTION_build {
    my $self = shift;
    # below requires Config::Model 2.062
    system ($^X, qw!-I lib -MConfig::Model::Utils::GenClassPod -e gen_class_pod();!) == 0
                    or die "gen-class-pod failed: $?";
    $self->SUPER::ACTION_build;
}
SUBCLASS


my @version_info = @ARGV ? ( dist_version => $ARGV[0] ) : ();

my %appli_files = map { ( $_, $_ ) } glob("lib/Config/Model/*.d/*");

my $build = $class->new(
    module_name => 'Config::Model',
    @version_info,
    license       => 'lgpl',
    appli_files   => \%appli_files,
    dist_abstract => 'Describe, edit and validate configuration data',
    dist_author   => 'Dominique Dumont (ddumont at cpan dot org)',

  'build_requires' => {
    'Config::Model::Tester' => '2.059',
    'Module::Build' => '0.34',
    'Test::Differences' => '0',
    'Test::Exception' => '0',
    'Test::File::Contents' => '0',
    'Test::Memory::Cycle' => '0',
    'Test::More' => '0',
    'Test::Warn' => '0.11',
    'YAML' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.34'
  },
  'recommends' => {
    'Fuse' => '0',
    'Term::ReadLine' => '0',
    'Text::Levenshtein::Damerau' => '0',
    'YAML' => '0'
  },
  'requires' => {
    'Carp' => '0',
    'Carp::Assert::More' => '0',
    'Cwd' => '0',
    'Data::Dumper' => '0',
    'Encode' => '0',
    'English' => '0',
    'Fcntl' => '0',
    'File::Copy' => '0',
    'File::HomeDir' => '0',
    'File::Path' => '0',
    'Hash::Merge' => '0.12',
    'IO::File' => '0',
    'JSON' => '0',
    'List::MoreUtils' => '0',
    'List::Util' => '0',
    'Log::Log4perl' => '1.11',
    'Mouse' => '0',
    'Mouse::Role' => '0',
    'Mouse::Util' => '0',
    'Mouse::Util::TypeConstraints' => '0',
    'MouseX::NativeTraits' => '0',
    'MouseX::StrictConstructor' => '0',
    'POSIX' => '0',
    'Parse::RecDescent' => 'v1.90.0',
    'Path::Tiny' => '0.070',
    'Pod::POM' => '0',
    'Pod::Simple' => '3.23',
    'Pod::Text' => '0',
    'Regexp::Common' => '0',
    'Scalar::Util' => '0',
    'Storable' => '0',
    'Text::Diff' => '0',
    'Text::Levenshtein::Damerau' => '0',
    'Text::Wrap' => '0',
    'parent' => '0',
    'perl' => '5.010'
  },

    # cleanup required by t/auto_read.t
    # PreGrammar.pm is created by t/value_computer.t
    add_to_cleanup => [ qw/PreGrammar.pm wr_root/ ],
);

$build->add_build_element('pl');
$build->add_build_element('appli');

$build->create_build_script;
