#!/usr/bin/perl
use Module::Build;
my $mbld = Module::Build->new(
# 'module_name'                   => 'Curses::Simp',
  'dist_name'                     => 'Curses-Simp',
# 'dist_version_from'             => 'Simp.pm',
  'dist_version'                  => '1.4.A8UG1gG',
  'dist_abstract'                 => 'Curses Not Quite Simple',
  'dist_author'                   => 'Pip Stuart <Pip@CPAN.Org>',
# 'create_readme'                 => '1',
# 'create_makefile_pl'            => '1', # 'traditional',
  'license'                       => 'gpl',
  'script_files'                  => {
  },
  'pm_files'                      => {
    'Simp.pm'                       => 'lib/Curses/Simp.pm',
  },
  'requires'                      => {
    'Curses'                        => '0',
    'Math::BaseCnv'                 => '0',
    'Test'                          => '0',
    'Test::Pod'                     => '0',
    'Test::Pod::Coverage'           => '0',
    'Tie::Array'                    => '0',
  },
);
$mbld->create_build_script();