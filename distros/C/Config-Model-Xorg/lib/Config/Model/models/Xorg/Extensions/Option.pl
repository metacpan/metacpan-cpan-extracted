#
# This file is part of Config-Model-Xorg
#
# This software is Copyright (c) 2007-2018 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'element' => [
      'Composite',
      {
        'choice' => [
          'Disable',
          'Enable'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      }
    ],
    'name' => 'Xorg::Extensions::Option'
  }
]
;

