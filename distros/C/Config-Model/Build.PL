#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use Module::Build;

use warnings FATAL => qw(all);
use strict;

require v5.20 ;

# check that pod docs are up-to-date. This is redundant with the work done by
# dzil, but enables re-building the docs downstream.
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
    'Config::INI::Reader' => '0',
    'Config::Model::Tester' => '4.002',
    'Config::Model::Tester::Setup' => '0',
    'File::Copy' => '0',
    'File::Spec' => '0',
    'IO::File' => '0',
    'JSON' => '0',
    'Module::Build' => '0.34',
    'Path::Tiny' => '0.125',
    'TOML::Tiny' => '0',
    'Test::Differences' => '0',
    'Test::Exception' => '0',
    'Test::File::Contents' => '0',
    'Test::Log::Log4perl' => '0',
    'Test::Memory::Cycle' => '0',
    'Test::More' => '0',
    'Test::Perl::Critic' => '0',
    'Test::Pod' => '1.00',
    'Test::Synopsis::Expectation' => '0',
    'Test::Warn' => '0.11',
    'Text::Levenshtein::Damerau' => '0',
    'YAML::PP' => '0',
    'YAML::Tiny' => '0',
    'boolean' => '0',
    'lib' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.34'
  },
  'recommends' => {
    'Term::ReadLine' => '0',
    'Text::Levenshtein::Damerau' => '0'
  },
  'requires' => {
    'Carp' => '0',
    'Carp::Assert::More' => '0',
    'Cwd' => '0',
    'Data::Dumper' => '0',
    'Encode' => '0',
    'English' => '0',
    'Fcntl' => '0',
    'File::HomeDir' => '0',
    'File::Path' => '0',
    'Hash::Merge' => '0.12',
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
    'Path::Tiny' => '0.125',
    'Pod::Simple' => '3.23',
    'Pod::Text' => '0',
    'Regexp::Common' => '0',
    'Scalar::Util' => '0',
    'Storable' => '0',
    'Text::Levenshtein::Damerau' => '0',
    'Text::Wrap' => '0',
    'base' => '0',
    'feature' => '0',
    'open' => '0',
    'overload' => '0',
    'parent' => '0',
    'perl' => 'v5.20.0',
    'strict' => '0',
    'utf8' => '0',
    'vars' => '0',
    'warnings' => '0'
  },

    add_to_cleanup => [ qw/wr_root wr_root_p/ ],
);

$build->add_build_element('pl');
$build->add_build_element('conf');
$build->add_build_element('appli');

$build->create_build_script;
