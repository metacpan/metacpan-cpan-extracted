# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use 5.008003;
use strict;
use warnings;
use lib 'buildlib';
use Clownfish::Build;

my $builder = Clownfish::Build->new(
    module_name => 'Clownfish',
    license     => 'apache',
    dist_author =>
        'The Apache Lucy Project <dev at lucy dot apache dot org>',
    dist_version       => '0.6.3',
    dist_abstract      => 'Apache Clownfish Runtime',
    requires           => { 'perl' => '5.8.3', },
    configure_requires => {
        'Module::Build'               => 0.280801,
        'Clownfish::CFC::Perl::Build' => 0.006003,
    },
    build_requires => {
        'Module::Build'      => 0.280801,
        'ExtUtils::CBuilder' => 0.21,
        'ExtUtils::ParseXS'  => 3.00,
        'Devel::PPPort'      => 3.14,
        'Clownfish::CFC'     => 0.006003,
    },
    no_index => {
        directory => [qw( buildlib )],
        package => [qw( Clownfish::Test )],
    },
    meta_merge => { keywords => [qw( clownfish )], },
    meta_add   => {
        resources => {
            homepage   => 'http://lucy.apache.org',
            repository => 'https://git-wip-us.apache.org/repos/asf/lucy-clownfish.git',
            bugtracker => 'https://issues.apache.org/jira/browse/CLOWNFISH',
        },
    },
    add_to_cleanup => [
        qw(
            Clownfish-*
            MANIFEST.bak
            perltidy.ERR
            *.pdb
            *.manifest
            ),
    ],
);

$builder->create_build_script();

