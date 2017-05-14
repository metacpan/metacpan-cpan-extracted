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
use Config;

use Alien::Base::ModuleBuild;

my $builder = Alien::Base::ModuleBuild->new(
    module_name        => 'Alien::LibBigWig',
    dist_abstract      => 'Installation of libBigWig for Perl',
    license            => 'open_source',
    configure_requires => { 'Alien::Base::ModuleBuild' => 0, 'Alien::Base' => 0 },
    requires           => {
        'perl'        => '5.8.1',
        'Alien::Base' => 0,
    },
    dist_author      => 'Andy Yates <ayates@ebi.ac.uk>',
    alien_name       => 'libBigWig',
    alien_repository => {
        protocol       => 'https',
        host           => 'github.com',
        location       => 'dpryan79/libBigWig/archive/',
        exact_filename => '0.3.3.tar.gz',
        exact_version  => '0.3.3',
    },
    alien_build_commands   => ["make lib CC=$Config{cc} CFLAGS=\"-fPIC -g -Wall -O2\""],
    alien_install_commands => [
        'mkdir -p %s/lib',
        'cp libBigWig.* %s/lib',
        'mkdir -p %s/include',
        'cp *.h %s/include',
    ],
);
$builder->create_build_script;