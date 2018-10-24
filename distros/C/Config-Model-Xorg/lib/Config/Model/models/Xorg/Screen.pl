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
      'Device',
      {
        'description' => 'specifies the Device section to be used for this
       screen. This is what ties a specific graphics card to a
       screen.',
        'refer_to' => '! Device',
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'Monitor',
      {
        'description' => 'specifies which monitor description is to be used
              for this screen. If a Monitor name is not specified, a
              default configuration is used. Currently the default
              configuration may not function as expected on all plat-
              forms.',
        'refer_to' => '! Monitor',
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'VideoAdaptor',
      {
        'description' => 'specifies an optional Xv video adaptor
              description to be used with this screen.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Display',
      {
        'cargo' => {
          'config_class_name' => 'Xorg::Screen::Display',
          'type' => 'node'
        },
        'description' => 'Each Screen section may have multiple Display
              subsections. The "active" Display subsection is the
              first that matches the depth and/or fbbpp values being
              used, or failing that, the first that has neither a
              depth or fbbpp value specified. The Display subsections
              are optional. When there isn\'t one that matches the
              depth and/or fbbpp values being used, all the parameters
              that can be specified here fall back to their
              defaults.',
        'index_type' => 'integer',
        'max_index' => 32,
        'min_index' => 1,
        'type' => 'hash'
      },
      'Option',
      {
        'config_class_name' => 'Xorg::Screen::Option',
        'type' => 'node'
      },
      'DefaultDepth',
      {
        'description' => 'specifies which color depth the server should use by default. The -depth command line option can be used to override this. If neither is specified, the default depth is driver-specific, but in most cases is 8.',
        'refer_to' => '- Display',
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'DefaultFbBpp',
      {
        'description' => 'specifies which framebuffer layout to use by
              default.  The -fbbpp command line option can be used to
              override this.  In most cases the driver will chose the
              best default value for this.  The only case where there
              is even a choice in this value is for depth 24, where
              some hardware supports both a packed 24 bit framebuffer
              layout and a sparse 32 bit framebuffer layout.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'Xorg::Screen'
  }
]
;

