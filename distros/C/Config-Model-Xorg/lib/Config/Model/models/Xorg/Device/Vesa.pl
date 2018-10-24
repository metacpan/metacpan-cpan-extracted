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
      'ShadowFB',
      {
        'description' => 'Enable or disable use of the shadow framebuffer layer. This option is recommended for performance reasons.',
        'type' => 'leaf',
        'upstream_default' => 1,
        'value_type' => 'boolean'
      },
      'ModeSetClearScreen',
      {
        'description' => 'Enable or disable use of the shadow framebuffer layer. This option is recommended for performance reasons.',
        'type' => 'leaf',
        'upstream_default' => 1,
        'value_type' => 'boolean'
      }
    ],
    'name' => 'Xorg::Device::Vesa'
  }
]
;

