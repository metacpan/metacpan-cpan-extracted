#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2016 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'class_description' => 'generated from LCDd.conf',
    'element' => [
      'AutoRotate',
      {
        'description' => 'If set to no, LCDd will start with screen rotation disabled. This has the
same effect as if the ToggleRotateKey had been pressed. Rotation will start
if the ToggleRotateKey is pressed. Note that this setting does not turn off
priority sorting of screens. ',
        'type' => 'leaf',
        'upstream_default' => 'on',
        'value_type' => 'boolean',
        'write_as' => [
          'off',
          'on'
        ]
      },
      'Backlight',
      {
        'choice' => [
          'off',
          'open',
          'on'
        ],
        'description' => 'Set master backlight setting. If set to \'open\' a client may control the
backlight for its own screens (only). ',
        'type' => 'leaf',
        'upstream_default' => 'open',
        'value_type' => 'enum'
      },
      'Bind',
      {
        'description' => 'Tells the driver to bind to the given interface. ',
        'type' => 'leaf',
        'upstream_default' => '127.0.0.1',
        'value_type' => 'uniline'
      },
      'Driver',
      {
        'choice' => [
          'bayrad',
          'CFontz',
          'CFontzPacket',
          'curses',
          'CwLnx',
          'ea65',
          'EyeboxOne',
          'g15',
          'glcd',
          'glcdlib',
          'glk',
          'hd44780',
          'icp_a106',
          'imon',
          'imonlcd',
          'IOWarrior',
          'irman',
          'joy',
          'lb216',
          'lcdm001',
          'lcterm',
          'lirc',
          'lis',
          'MD8800',
          'mdm166a',
          'ms6931',
          'mtc_s16209x',
          'MtxOrb',
          'mx5000',
          'NoritakeVFD',
          'picolcd',
          'pyramid',
          'rawserial',
          'sdeclcd',
          'sed1330',
          'sed1520',
          'serialPOS',
          'serialVFD',
          'shuttleVFD',
          'sli',
          'stv5730',
          'svga',
          't6963',
          'text',
          'tyan',
          'ula200',
          'vlsys_m428',
          'xosd'
        ],
        'description' => 'Tells the server to load the given drivers. Multiple lines can be given.
The name of the driver is case sensitive and determines the section
where to look for further configuration options of the specific driver
as well as the name of the dynamic driver module to load at runtime.
The latter one can be changed by giving a File= directive in the
driver specific section.

The following drivers are supported:
  bayrad, CFontz, CFontzPacket, curses, CwLnx, ea65, EyeboxOne, g15, glcd,
  glcdlib, glk, hd44780, icp_a106, imon, imonlcd,, IOWarrior, irman, joy,
  lb216, lcdm001, lcterm, lirc, lis, MD8800,, mdm166a, ms6931, mtc_s16209x,
  MtxOrb, mx5000, NoritakeVFD, picolcd,, pyramid, rawserial, sdeclcd,
  sed1330, sed1520, serialPOS, serialVFD, shuttleVFD, sli,, stv5730, svga,
  t6963, text, tyan, ula200, vlsys_m428, xosd',
        'type' => 'check_list'
      },
      'DriverPath',
      {
        'default' => 'server/drivers/',
        'description' => 'Where can we find the driver modules ?
IMPORTANT: Make sure to change this setting to reflect your
           specific setup! Otherwise LCDd won\'t be able to find
           the driver modules and will thus not be able to
           function properly.
NOTE: Always place a slash as last character !',
        'match' => '/$',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Foreground',
      {
        'description' => 'The server will stay in the foreground if set to yes.',
        'type' => 'leaf',
        'upstream_default' => 'no,legal:yes,no',
        'value_type' => 'uniline'
      },
      'GoodBye',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'type' => 'list'
      },
      'Heartbeat',
      {
        'choice' => [
          'off',
          'open',
          'on'
        ],
        'description' => 'Set master heartbeat setting. If set to \'open\' a client may control the
heartbeat for its own screens (only). ',
        'type' => 'leaf',
        'upstream_default' => 'open',
        'value_type' => 'enum'
      },
      'Hello',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'type' => 'list'
      },
      'NextScreenKey',
      {
        'default' => 'Right',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Port',
      {
        'description' => 'Listen on this specified port. ',
        'type' => 'leaf',
        'upstream_default' => '13666',
        'value_type' => 'integer'
      },
      'PrevScreenKey',
      {
        'default' => 'Left',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ReportLevel',
      {
        'description' => 'Sets the reporting level; defaults to warnings and errors only.',
        'max' => '5',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '2',
        'value_type' => 'integer'
      },
      'ReportToSyslog',
      {
        'description' => 'Should we report to syslog instead of stderr? ',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'ScrollDownKey',
      {
        'type' => 'leaf',
        'upstream_default' => 'Down',
        'value_type' => 'uniline'
      },
      'ScrollUpKey',
      {
        'type' => 'leaf',
        'upstream_default' => 'Up',
        'value_type' => 'uniline'
      },
      'ServerScreen',
      {
        'choice' => [
          'on',
          'off',
          'blank'
        ],
        'description' => 'If yes, the the serverscreen will be rotated as a usual info screen. If no,
it will be a background screen, only visible when no other screens are
active. The special value \'blank\' is similar to no, but only a blank screen
is displayed. ',
        'type' => 'leaf',
        'upstream_default' => 'on',
        'value_type' => 'enum'
      },
      'TitleSpeed',
      {
        'description' => 'set title scrolling speed ',
        'max' => '10',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '10',
        'value_type' => 'integer'
      },
      'ToggleRotateKey',
      {
        'default' => 'Enter',
        'description' => 'The "...Key=" lines define what the server does with keypresses that
don\'t go to any client. The ToggleRotateKey stops rotation of screens, while
the PrevScreenKey and NextScreenKey go back / forward one screen (even if
rotation is disabled.
Assign the key string returned by the driver to the ...Key setting. These
are the defaults:',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'User',
      {
        'description' => 'User to run as.  LCDd will drop its root privileges and run as this user
instead. ',
        'type' => 'leaf',
        'upstream_default' => 'nobody',
        'value_type' => 'uniline'
      },
      'WaitTime',
      {
        'description' => 'Sets the default time in seconds to displays a screen. ',
        'type' => 'leaf',
        'upstream_default' => '4',
        'value_type' => 'integer'
      }
    ],
    'name' => 'LCDd::server'
  }
]
;

