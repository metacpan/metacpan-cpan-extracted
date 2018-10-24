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
      'TwinView',
      {
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'MetaModes',
      {
        'description' => 'Incomplete model. TBD',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'CrtcNumber',
      {
        'type' => 'leaf',
        'value_type' => 'integer'
      }
    ],
    'name' => 'Xorg::Device::Nvidia'
  }
]
;

