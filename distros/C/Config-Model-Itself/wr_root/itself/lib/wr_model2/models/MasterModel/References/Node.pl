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
      'host',
      {
        'refer_to' => '- host',
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'if',
      {
        'computed_refer_to' => {
          'formula' => '  - host:$h if ',
          'variables' => {
            'h' => '- host'
          }
        },
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'ip',
      {
        'compute' => {
          'formula' => '$ip',
          'variables' => {
            'card' => '- if',
            'h' => '- host',
            'ip' => '- host:$h if:$card ip'
          }
        },
        'type' => 'leaf',
        'value_type' => 'string'
      }
    ],
    'name' => 'MasterModel::References::Node'
  }
]
;

