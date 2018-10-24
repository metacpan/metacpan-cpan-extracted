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
      'DefaultServerLayout',
      {
        'description' => 'This specifies the default ServerLayout section to use in the absence of the layout command line option.',
        'refer_to' => '! ServerLayout',
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'NoTrapSignals',
      {
        'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'DontVTSwitch',
      {
        'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'DontZap',
      {
        'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'DontZoom',
      {
        'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'DisableVidModeExtension',
      {
        'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'AllowNonLocalXvidtune',
      {
        'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'DisableModInDev',
      {
        'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'AllowMouseOpenFail',
      {
        'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'VTSysReq',
      {
        'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XkbDisable',
      {
        'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'NoPM',
      {
        'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'Xinerama',
      {
        'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'AllowDeactivateGrabs',
      {
        'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'AllowClosedownGrabs',
      {
        'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'IgnoreABI',
      {
        'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'VTInit',
      {
        'description' => 'Runs command after the VT used by the server has been opened. The command string is passed to "/bin/sh -c", and is run with the real user\'s id with stdin and stdout set to the VT. The purpose of this option is to allow system dependent VT initialisation commands to be run. This option should rarely be needed. Default: not set.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'BlankTime',
      {
        'description' => 'sets the inactivity timeout for the blank phase of the screensaver. time is in minutes. This is equivalent to the Xorg server\'s -s flag, and the value can be changed at run-time with xset(1). Default: 10 minutes.',
        'type' => 'leaf',
        'upstream_default' => 10,
        'value_type' => 'integer'
      },
      'StandbyTime',
      {
        'description' => 'sets the inactivity timeout for the standby phase of DPMS mode. time is in minutes, and the value can be changed at run-time with xset(1). Default: 20 minutes. This is only suitable for VESA DPMS compatible monitors, and may not be supported by all video drivers. It is only enabled for screens that have the "DPMS" option set (see the MONITOR section below).',
        'type' => 'leaf',
        'upstream_default' => 20,
        'value_type' => 'integer'
      },
      'SuspendTime',
      {
        'description' => 'sets the inactivity timeout for the suspend phase of DPMS mode. time is in minutes, and the value can be changed at run-time with xset(1). Default: 30 minutes. This is only suitable for VESA DPMS compatible monitors, and may not be supported by all video drivers. It is only enabled for screens that have the "DPMS" option set (see the MONITOR section below).',
        'type' => 'leaf',
        'upstream_default' => 30,
        'value_type' => 'integer'
      },
      'OffTime',
      {
        'description' => 'sets the inactivity timeout for the off phase of DPMS mode. time is in minutes, and the value can be changed at run-time with xset(1). Default: 40 minutes. This is only suitable for VESA DPMS compatible monitors, and may not be supported by all video drivers. It is only enabled for screens that have the "DPMS" option set (see the MONITOR section below).',
        'type' => 'leaf',
        'upstream_default' => 40,
        'value_type' => 'integer'
      },
      'Pixmap',
      {
        'choice' => [
          24,
          32
        ],
        'description' => 'This sets the pixmap format to use for depth 24. Allowed values for bpp are 24 and 32. Default: 32 unless driver constraints don\'t allow this (which is rare). Note: some clients don\'t behave well when this value is set to 24.',
        'type' => 'leaf',
        'upstream_default' => 32,
        'value_type' => 'enum'
      },
      'PC98',
      {
        'description' => 'Specify that the machine is a Japanese PC-98 machine. This should not be enabled for anything other than the Japanese-specific PC-98 architecture. Default: auto-detected.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'HandleSpecialKeys',
      {
        'choice' => [
          'Always',
          'Never',
          'WhenNeeded'
        ],
        'description' => 'This option controls when the server uses the builtin handler to process special key combinations (such as Ctrl+Alt+Backspace). Normally the XKEYBOARD extension keymaps will provide mappings for each of the special key combinations, so the builtin handler is not needed unless the XKEYBOARD extension is disabled. The value of when can be Always, Never, or WhenNeeded. Default: Use the builtin handler only if needed. The server will scan the keymap for a mapping to the Terminate action and, if found, use XKEYBOARD for processing actions, otherwise the builtin handler will be used.',
        'type' => 'leaf',
        'upstream_default' => 'WhenNeeded',
        'value_type' => 'enum'
      },
      'AIGLX',
      {
        'choice' => [
          'off',
          'on'
        ],
        'description' => 'enable or disable AIGLX.',
        'type' => 'leaf',
        'upstream_default' => 'on',
        'value_type' => 'enum'
      },
      'UseDefaultFontPath',
      {
        'choice' => [
          'off',
          'on'
        ],
        'description' => 'Include the default font path even if other paths are specified in xorg.conf. If enabled, other font paths are included as well.',
        'type' => 'leaf',
        'upstream_default' => 'on',
        'value_type' => 'enum'
      }
    ],
    'name' => 'Xorg::ServerFlags'
  }
]
;

