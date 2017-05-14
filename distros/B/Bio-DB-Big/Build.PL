#!/usr/bin/env perl

# Copyright [2015-2017] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass( class => 'Module::Build::Big' );

my $build = $class->new(

    module_name       => 'Bio::DB::Big',
    dist_version_from => 'lib/Bio/DB/Big.pm',
    dist_author       => 'Andy Yates',
    dist_abstract =>
      'Perl interface to bigWigLib for accessing the kent big formats',
    license => 'open_source',

    extra_compiler_flags => [
        '-D_IOLIB=2', '-D_FILE_OFFSET_BITS=64',

        # warnings not treated as errors
        '-Wno-error',

        # Don't care about unused results from function calls
        '-Wno-unused-result',
    ],

    build_requires     => { 'ExtUtils::CBuilder' => 0, },
    configure_requires => { 'Module::Build'      => 0.42, },
    test_requires      => { 'Test::Fake::HTTPD', => 0, 'Test::Differences' => 0, 'Test::Exception' => 0},
    requires           => { 'perl'               => '5.008' },
    meta_merge         => {
        'resources' => {
            'repository' => 'https://github.com/Ensembl/Bio-DB-Big',
        },
    },
);

$build->find_libbigwig;
$build->set_include_and_compiler_flags;
$build->create_build_script;

exit 0;

package Module::Build::Big;

use Module::Load::Conditional qw(can_load);
use base 'Module::Build';

sub find_libbigwig {
    my ($self) = @_;

    # If either of these are set, we expect to find the libBigWig files there:
    # (They're explicitly set by the user, so we shouldn't fall back to
    # finding another copy somewhere else.)
    if ( my $dir = $self->args('libbigwig') ) {
        return 1 if $self->find_libbigwig_in_build_dir($dir);
        return 1 if $self->find_libbigwig_in_install_dir($dir);
        $self->die_libbigwig_not_found(
"--libbigwig '$dir' command line parameter does not contain expected files\n"
        );
    }
    elsif ( $dir = $ENV{'LIBBIGWIG_DIR'} ) {
        return 1 if $self->find_libbigwig_in_build_dir($dir);
        return 1 if $self->find_libbigwig_in_install_dir($dir);
        $self->die_libbigwig_not_found(
"LIGBIGWIG_DIR=$ENV{LIBBIGWIG_DIR} environment variable does not contain expected files\n"
        );
    }

    # Search through remaining possible (but not fatal) locations:
    my $found = 0;
    foreach my $dir (
        $self->prefix, from_Alien(),
        scalar `pkg-config --variable=libdir libBigWig 2>/dev/null`,
        qw{ /usr /usr/local /usr/share /opt/local },
      )
    {
        if ( $dir and $self->find_libbigwig_in_install_dir($dir) ) {
            $found = 1;
            last;
        }
    }
    return 1 if $found;

    $self->die_libbigwig_not_found();
}

sub set_include_and_compiler_flags {
    my ($self) = @_;

    my $libbigwig_include = $self->config_data('libbigwig_include');
    my $libbigwig_lib     = $self->config_data('libbigwig_lib');
    my $static            = $self->args('static');
    $self->include_dirs( [$libbigwig_include] );
    if ($static) {
        $self->extra_linker_flags( "-L$libbigwig_lib", '-lBigWig', '-lpthread',
            '-lz' );
    }
    else {
        $self->extra_linker_flags(
            "-L$libbigwig_lib", "-Wl,-rpath,$libbigwig_lib",
            '-lBigWig',         '-lpthread',
            '-lz'
        );
    }
}

# Look for the library and header in the location where htslib was compiled
sub find_libbigwig_in_build_dir {
    my ( $self, $root ) = @_;

    chomp($root);
    $root =~ s{/$}{};
    $root =~ s{/(lib|include)$}{};

    my $libbigwig_lib     = "$root";
    my $libbigwig_include = "$root";
    if ( -f "$libbigwig_lib/libBigWig.a" && -f "$libbigwig_include/bigWig.h" ) {
        $self->config_data( 'libbigwig_lib'     => $libbigwig_lib );
        $self->config_data( 'libbigwig_include' => $libbigwig_include );
        return 1;
    }
    else {
        return 0;
    }
}

sub find_libbigwig_in_install_dir {
    my ( $self, $root ) = @_;

    chomp($root);
    $root =~ s{/$}{};
    $root =~ s{/(lib|include)$}{};

    my $libbigwig_lib     = "$root/lib";
    my $libbigwig_include = "$root/include";
    if ( -f "$libbigwig_lib/libBigWig.a" && -f "$libbigwig_include/bigWig.h" ) {
        $self->config_data( 'libbigwig_lib'     => $libbigwig_lib );
        $self->config_data( 'libbigwig_include' => $libbigwig_include );
        return 1;
    }
    else {
        return 0;
    }
}

sub die_libbigwig_not_found {
    my ( $self, $msg ) = @_;

    $msg ||= '';
    die $msg, <<END;

This module requires libBigWig (https://github.com/dpryan79/libBigWig)
Install it if you have not done so already.

This script will attempt to locate libBigWig by looking for BigWig.h and libBigWig.a in:

  1. --libbigwig command line argument
  2. LIBBIGWIG_DIR environment variable
  3. --prefix command line argument (which also sets installation location)
  4. Alien::LibBigWig dependency resolver
  5. common library locations: /usr /usr/local, /usr/share, /opt/local

END

}

sub from_Alien {
    can_load(
        modules => { 'Alien::LibBigWig' => undef, 'File::ShareDir' => undef } )
      && File::ShareDir::dist_dir('Alien-LibBigWig');
}
