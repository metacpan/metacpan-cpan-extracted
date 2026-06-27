#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2023, 2026 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;
use v5.20;
use utf8;

return [
  {
    'class_description' => 'generated from LCDd.conf',
    'description' => {
      'PauseKey' => 'keypad settings
Keyname      Function
             Normal context              Menu context
-------      --------------              ------------
PauseKey     Pause/Continue              Enter/select
BackKey      Back(Go to previous screen) Up/Left
ForwardKey   Forward(Go to next screen)  Down/Right
MainMenuKey  Open main menu              Exit/Cancel'
    },
    'element' => [
      'BackKey',
      {
        'default' => 'UpKey',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Device',
      {
        'default' => '/dev/ttyS1',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ForwardKey',
      {
        'default' => 'DownKey',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'MainMenuKey',
      {
        'default' => 'RightKey',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'PauseKey',
      {
        'default' => 'LeftKey',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::lcdm001'
  }
]
;
