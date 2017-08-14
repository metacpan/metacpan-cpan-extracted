#!/usr/bin/env perl

use strict;
use warnings;
use Alien::Base::ModuleBuild '0.025';

my $minver = '1.1.0f';

my $builder = Alien::Base::ModuleBuild->new (
    module_name => 'Alien::OpenSSL::Static',
    license => 'perl',
    configure_requires => {
        'Alien::Base::ModuleBuild' => '0.025',
        'Module::Build' => '0.38',
        'Test::More' => 0,
    },
    requires => {
        'perl' => '5.8.1',
        'Alien::Base' => '0.025',
    },
    alien_name => 'openssl',
    alien_repository => {
        protocol => 'local',
        location => 'source',
        exact_filename => "openssl-${minver}.tar.gz",
    },
    alien_version_check => '%{pkg_config} --atleast-version '
      . $minver .' %n && %{pkg_config} --modversion %n',
    alien_stage_install => 0,
    alien_build_commands => [
        'sh config no-shared --prefix=%s',
        'make',
    ],
    alien_install_commands => [
        'make install_sw',
    ],
    meta_merge => {
        resources => {
            homepage => 'https://github.com/ollyg/alien-openssl-static',
            bugtracker => 'https://github.com/ollyg/alien-openssl-static/issues',
            repository  => 'git://github.com/ollyg/alien-openssl-static.git',
        },
    },
    script_files => [
      'bin/openssl-env-bash',
      'bin/openssl-env-perl'
    ],
);

my %args = $builder->args;

my $version;
$version = $args{version} if(exists $args{version});

if ( defined($version) ) {
    my $location = ".../source/openssl-".$version.".tar.gz";
    print "Downloading from $location\n";
    $builder->alien_version_check('%{pkg_config} --exact-version '
      . $version .' %n && %{pkg_config} --modversion %n');
    $builder->alien_repository->{exact_filename} = "openssl-$version.tar.gz";
}

$builder->create_build_script;
