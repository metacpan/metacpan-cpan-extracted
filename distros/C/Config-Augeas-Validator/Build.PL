#    Copyright (c) 2011 Raphaël Pinson.
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
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

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Config::Augeas::Validator',
    license     => 'lgpl',
    dist_author => 'Raphaël Pinson <raphink@cpan.org>',
    dist_abstract => 'A generic configuration validator API',
    requires    => {
        'Class::Accessor'  => 0,
        'Config::Augeas'   => 0.801,
        'Config::IniFiles' => 0,
    },
    build_requires => {
        'Test::More'      => 0,
    },
    scripts => [
        'bin/augeas-validator',
    ],
    create_readme      => 1,
    sign               => 1,
    create_makefile_pl => 'traditional',
    meta_merge => {
       resources   => {
           repository => 'https://code.launchpad.net/deput://github.com/raphink/Config--Augeas--Validator',
       },
       keywords => [
          'configuration',
          'configuration management',
          'validator',
          'augeas',
       ],
    },
);

$builder->create_build_script();

