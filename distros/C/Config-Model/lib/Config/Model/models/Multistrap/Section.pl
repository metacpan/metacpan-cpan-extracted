#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

return [
  {
    'accept' => [
      '\\w+',
      {
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'Handling unknown parameter as unlinie value.'
      }
    ],
    'element' => [
      'packages',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'type' => 'list'
      },
      'components',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'type' => 'list'
      },
      'source',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'keyring',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'suite',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'omitdebsrc',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      }
    ],
    'name' => 'Multistrap::Section'
  }
]
;

