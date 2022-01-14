#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

return [
  {
    'element' => [
      'allow_override',
      {
        'compute' => {
          'formula' => '$upstream_knowns',
          'use_as_upstream_default' => 1,
          'variables' => {
            'upstream_knowns' => '- use_as_upstream_default'
          }
        },
        'description' => 'Allow user to override computed valueFor more details, see L<doc|Config::Model::ValueComputer.pm/"compute override"> ',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'use_as_upstream_default',
      {
        'description' => 'Indicate that the computed value is known by the application and does not need to be written in the configuration file. Implies allow_override.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      }
    ],
    'include' => [
      'Itself::MigratedValue'
    ],
    'name' => 'Itself::ComputedValue'
  }
]
;

