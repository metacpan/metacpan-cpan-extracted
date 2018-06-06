#!/usr/bin/env perl
#  Copyright (C) 2015 Rocky Bernstein <rocky@cpan.org>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Module::Build;
use Config;

my $builder = Module::Build->new(
    module_name         => 'B::DeparseTree',
    add_to_cleanup      => [ 'p5-B-DeparseTree-*', 'tmp*', '*.got'  ],
    create_makefile_pl  => 'passthrough',
    dist_abstract       =>
    'Like B::Deparse, but keeps tree structure indexable by OP address.',
    dist_author         => 'Rocky Bernstein <rocky@cpan.org>',
    dist_version_from   => 'lib/B/DeparseTree.pm',
    license             => 'gpl',
    needs_compiler      => 0,
    release_status      => 'stable',
    configure_requires  => {
	'Module::Build' => '0.4214',

    },
    test_requires  => {
        'Test::Simple' => '0.81',
	    'Text::Diff' => 0,
    },
    requires => {
	'perl'                              => '5.016000',
	'rlib'                              => '0.02',
        'version'                           => 0,
	# Data::Printer could be optional, but it's
	# useful, so we'll force including it.
        'Data::Printer'                     => '0.40',
    },
    sign                => ($ENV{PERL_MB_NOSIGN} ? 0 : 1),
    );

$builder->create_build_script();
