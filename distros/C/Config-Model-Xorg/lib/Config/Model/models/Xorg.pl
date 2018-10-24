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
    'class_description' => 'Top level Xorg configuration.',
    'element' => [
      'Files',
      {
        'config_class_name' => 'Xorg::Files',
        'description' => 'File pathnames',
        'type' => 'node'
      },
      'Module',
      {
        'config_class_name' => 'Xorg::Module',
        'description' => 'Dynamic module loading',
        'type' => 'node'
      },
      'CorePointer',
      {
        'description' => 'name of the core (primary) keyboard device',
        'refer_to' => '! InputDevice',
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'CoreKeyboard',
      {
        'description' => 'name of the core (primary) keyboard device',
        'refer_to' => '! InputDevice',
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'InputDevice',
      {
        'cargo' => {
          'config_class_name' => 'Xorg::InputDevice',
          'type' => 'node'
        },
        'default_with_init' => {
          'kbd' => 'Driver=keyboard',
          'mouse' => 'Driver=mouse'
        },
        'description' => 'Input device(s) description',
        'index_type' => 'string',
        'type' => 'hash'
      },
      'MultiHead',
      {
        'default' => 0,
        'description' => 'Set this to one if you plan to use more than 1 display',
        'level' => 'important',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'Monitor',
      {
        'cargo' => {
          'config_class_name' => 'Xorg::Monitor',
          'type' => 'node'
        },
        'description' => 'Monitor description',
        'index_type' => 'string',
        'type' => 'hash'
      },
      'Device',
      {
        'cargo' => {
          'config_class_name' => 'Xorg::Device',
          'type' => 'node'
        },
        'description' => 'Graphics device description',
        'index_type' => 'string',
        'type' => 'hash'
      },
      'Modes',
      {
        'cargo' => {
          'config_class_name' => 'Xorg::Monitor::Mode',
          'type' => 'node'
        },
        'description' => 'Video modes descriptions',
        'index_type' => 'string',
        'type' => 'hash'
      },
      'Screen',
      {
        'cargo' => {
          'config_class_name' => 'Xorg::Screen',
          'type' => 'node'
        },
        'description' => 'Screen configuration',
        'index_type' => 'string',
        'type' => 'hash'
      },
      'ServerLayout',
      {
        'cargo' => {
          'config_class_name' => 'Xorg::ServerLayout',
          'type' => 'node'
        },
        'description' => 'represents the binding of one or more screens
       (Screen sections) and one or more input devices (InputDevice
       sections) to form a complete configuration.',
        'index_type' => 'string',
        'type' => 'hash'
      },
      'ServerFlags',
      {
        'config_class_name' => 'Xorg::ServerFlags',
        'description' => 'Server flags used to specify some global Xorg server options.',
        'type' => 'node'
      },
      'DRI',
      {
        'config_class_name' => 'Xorg::DRI',
        'description' => 'DRI-specific configuration',
        'type' => 'node'
      },
      'Extensions',
      {
        'config_class_name' => 'Xorg::Extensions',
        'description' => 'DRI-specific configuration',
        'type' => 'node'
      }
    ],
    'include_backend' => [
      'Xorg::ConfigDir'
    ],
    'name' => 'Xorg'
  },
  {
    'element' => [
      'Mode',
      {
        'description' => 'DRI mode, usually set to 0666',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'Xorg::DRI'
  }
]
;


