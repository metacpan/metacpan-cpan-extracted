#!/usr/bin/env perl

use strict;
use warnings;
use 5.010001;
use utf8;

use lib 'inc';
use My::ModuleBuild;

my $conf_cmd = [
  '%c',                     '--with-pic',
  '--prefix=%s',            '--disable-agent',
  '--disable-scripts',      '--disable-mibs',
  '--enable-ipv6',          '--with-mibs=""',
  '--with-perl-modules',    '--disable-embedded-perl',
  '--disable-manuals',      '--enable-blumenthal-aes',
  '--with-defaults',
];

my %module_build_args = (
  alien_autoconf_with_pic => 0,
  alien_build_commands =>
    ["%x -I../../inc -MMy::AlienPatch -e alien_patch", $conf_cmd, 'make'],
  alien_extra_site_config => {
    CFLAGS => $ENV{CFLAGS},
    LDFLAGS => $ENV{LDFLAGS},
  },

  # Not using FFI, default_store library only dynamic and needed for XS
  alien_isolate_dynamic => 0,
  alien_name            => 'netsnmp',

  # Headers referenced as net-snmp/xxx.h, autodiscovery appends net-snmp
  alien_provides_cflags => '-I${pcfiledir}/include',
  alien_provides_libs   => '-lnetsnmp',
  alien_repository      => {
    protocol       => 'https',
    host           => 'github.com',
    location       => '/netdisco/upstream-sources/blob/master/net-snmp/',
    exact_filename => 'net-snmp-5.9.4.tar.gz?raw=true',
  },
  alien_stage_install => 0,
  build_requires      => {
    "Alien::Base"        => '0.020',
    'Software::License' => '0',
  },
  configure_requires  => {
    "perl"               => '5.010001',
    'Alien::Base::ModuleBuild' => '0',
    "File::ShareDir"     => '1.03',
    "Module::Build"      => '0.42',
    "PkgConfig"          => '0.14026',
    "Test2::Suite"       => '0.000067'
  },
  create_license    => 1,
  create_readme     => 1,
  dist_abstract     => 'Build and install Net-SNMP',
  dist_author       => 'Eric A. Miller <emiller AT cpan DOT org>',
  dist_name         => 'Alien-SNMP',
  dist_version_from => 'lib/Alien/SNMP.pm',
  license           => 'bsd',
  module_name       => "Alien::SNMP",
  recommends        => {},
  requires          => {
    "Alien::Base"    => '0.020',
    "File::ShareDir" => '1.03',
    "parent"         => 0,
    "perl"           => '5.010001'
  },
  test_requires =>
    {"Test::Alien" => '0.16', "Test::More" => '0.94', "perl" => '5.010001'},

  meta_merge => {
    resources  => {
      repository => "http://github.com/ollyg/Alien-SNMP",
      bugtracker => 'https://github.com/ollyg/Alien-SNMP/issues',
    },
  },
);

my %fallback_build_requires
  = ("Test::Alien" => '0.16', "Test::More" => '0.94', "perl" => '5.010001');

unless (eval { Module::Build->VERSION(0.4004) }) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $builder = My::ModuleBuild->new(%module_build_args);

$builder->create_build_script;
