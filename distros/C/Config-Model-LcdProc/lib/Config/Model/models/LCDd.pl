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
    'class_description' => '

Model information was extracted from /etc/LCDd.conf',
    'copyright' => [
      '2011-2017, Dominique Dumont',
      '1999-2017, William Ferrell and others'
    ],
    'element' => [
      'server',
      {
        'config_class_name' => 'LCDd::server',
        'type' => 'node'
      },
      'CFontz',
      {
        'config_class_name' => 'LCDd::CFontz',
        'type' => 'warped_node'
      },
      'CFontzPacket',
      {
        'config_class_name' => 'LCDd::CFontzPacket',
        'type' => 'warped_node'
      },
      'CwLnx',
      {
        'config_class_name' => 'LCDd::CwLnx',
        'type' => 'warped_node'
      },
      'EyeboxOne',
      {
        'config_class_name' => 'LCDd::EyeboxOne',
        'type' => 'warped_node'
      },
      'IOWarrior',
      {
        'config_class_name' => 'LCDd::IOWarrior',
        'type' => 'warped_node'
      },
      'IrMan',
      {
        'config_class_name' => 'LCDd::IrMan',
        'type' => 'warped_node'
      },
      'MD8800',
      {
        'config_class_name' => 'LCDd::MD8800',
        'type' => 'warped_node'
      },
      'MtxOrb',
      {
        'config_class_name' => 'LCDd::MtxOrb',
        'type' => 'warped_node'
      },
      'NoritakeVFD',
      {
        'config_class_name' => 'LCDd::NoritakeVFD',
        'type' => 'warped_node'
      },
      'Olimex_MOD_LCD1x9',
      {
        'config_class_name' => 'LCDd::Olimex_MOD_LCD1x9',
        'type' => 'warped_node'
      },
      'SureElec',
      {
        'config_class_name' => 'LCDd::SureElec',
        'type' => 'warped_node'
      },
      'bayrad',
      {
        'config_class_name' => 'LCDd::bayrad',
        'type' => 'warped_node'
      },
      'curses',
      {
        'config_class_name' => 'LCDd::curses',
        'type' => 'warped_node'
      },
      'ea65',
      {
        'config_class_name' => 'LCDd::ea65',
        'type' => 'warped_node'
      },
      'futaba',
      {
        'config_class_name' => 'LCDd::futaba',
        'type' => 'warped_node'
      },
      'g15',
      {
        'config_class_name' => 'LCDd::g15',
        'type' => 'warped_node'
      },
      'glcd',
      {
        'config_class_name' => 'LCDd::glcd',
        'type' => 'warped_node'
      },
      'glcdlib',
      {
        'config_class_name' => 'LCDd::glcdlib',
        'type' => 'warped_node'
      },
      'glk',
      {
        'config_class_name' => 'LCDd::glk',
        'type' => 'warped_node'
      },
      'hd44780',
      {
        'config_class_name' => 'LCDd::hd44780',
        'type' => 'warped_node'
      },
      'icp_a106',
      {
        'config_class_name' => 'LCDd::icp_a106',
        'type' => 'warped_node'
      },
      'imon',
      {
        'config_class_name' => 'LCDd::imon',
        'type' => 'warped_node'
      },
      'imonlcd',
      {
        'config_class_name' => 'LCDd::imonlcd',
        'type' => 'warped_node'
      },
      'irtrans',
      {
        'config_class_name' => 'LCDd::irtrans',
        'type' => 'warped_node'
      },
      'joy',
      {
        'config_class_name' => 'LCDd::joy',
        'type' => 'warped_node'
      },
      'lb216',
      {
        'config_class_name' => 'LCDd::lb216',
        'type' => 'warped_node'
      },
      'lcdm001',
      {
        'config_class_name' => 'LCDd::lcdm001',
        'type' => 'warped_node'
      },
      'lcterm',
      {
        'config_class_name' => 'LCDd::lcterm',
        'type' => 'warped_node'
      },
      'linux_input',
      {
        'config_class_name' => 'LCDd::linux_input',
        'type' => 'warped_node'
      },
      'lirc',
      {
        'config_class_name' => 'LCDd::lirc',
        'type' => 'warped_node'
      },
      'lis',
      {
        'config_class_name' => 'LCDd::lis',
        'type' => 'warped_node'
      },
      'mdm166a',
      {
        'config_class_name' => 'LCDd::mdm166a',
        'type' => 'warped_node'
      },
      'menu',
      {
        'config_class_name' => 'LCDd::menu',
        'type' => 'node'
      },
      'ms6931',
      {
        'config_class_name' => 'LCDd::ms6931',
        'type' => 'warped_node'
      },
      'mtc_s16209x',
      {
        'config_class_name' => 'LCDd::mtc_s16209x',
        'type' => 'warped_node'
      },
      'mx5000',
      {
        'config_class_name' => 'LCDd::mx5000',
        'type' => 'warped_node'
      },
      'picolcd',
      {
        'config_class_name' => 'LCDd::picolcd',
        'type' => 'warped_node'
      },
      'pyramid',
      {
        'config_class_name' => 'LCDd::pyramid',
        'type' => 'warped_node'
      },
      'rawserial',
      {
        'config_class_name' => 'LCDd::rawserial',
        'type' => 'warped_node'
      },
      'sdeclcd',
      {
        'config_class_name' => 'LCDd::sdeclcd',
        'type' => 'warped_node'
      },
      'sed1330',
      {
        'config_class_name' => 'LCDd::sed1330',
        'type' => 'warped_node'
      },
      'sed1520',
      {
        'config_class_name' => 'LCDd::sed1520',
        'type' => 'warped_node'
      },
      'serialPOS',
      {
        'config_class_name' => 'LCDd::serialPOS',
        'type' => 'warped_node'
      },
      'serialVFD',
      {
        'config_class_name' => 'LCDd::serialVFD',
        'type' => 'warped_node'
      },
      'shuttleVFD',
      {
        'config_class_name' => 'LCDd::shuttleVFD',
        'type' => 'warped_node'
      },
      'sli',
      {
        'config_class_name' => 'LCDd::sli',
        'type' => 'warped_node'
      },
      'stv5730',
      {
        'config_class_name' => 'LCDd::stv5730',
        'type' => 'warped_node'
      },
      'svga',
      {
        'config_class_name' => 'LCDd::svga',
        'type' => 'warped_node'
      },
      't6963',
      {
        'config_class_name' => 'LCDd::t6963',
        'type' => 'warped_node'
      },
      'text',
      {
        'config_class_name' => 'LCDd::text',
        'type' => 'warped_node'
      },
      'tyan',
      {
        'config_class_name' => 'LCDd::tyan',
        'type' => 'warped_node'
      },
      'ula200',
      {
        'config_class_name' => 'LCDd::ula200',
        'type' => 'warped_node'
      },
      'vlsys_m428',
      {
        'config_class_name' => 'LCDd::vlsys_m428',
        'type' => 'warped_node'
      },
      'xosd',
      {
        'config_class_name' => 'LCDd::xosd',
        'type' => 'warped_node'
      },
      'yard2LCD',
      {
        'config_class_name' => 'LCDd::yard2LCD',
        'type' => 'warped_node'
      }
    ],
    'level' => {
      'hidden' => [
        'CFontz',
        'CFontzPacket',
        'CwLnx',
        'EyeboxOne',
        'IOWarrior',
        'IrMan',
        'MD8800',
        'MtxOrb',
        'NoritakeVFD',
        'Olimex_MOD_LCD1x9',
        'SureElec',
        'bayrad',
        'curses',
        'ea65',
        'futaba',
        'g15',
        'glcd',
        'glcdlib',
        'glk',
        'hd44780',
        'icp_a106',
        'imon',
        'imonlcd',
        'irtrans',
        'joy',
        'lb216',
        'lcdm001',
        'lcterm',
        'linux_input',
        'lirc',
        'lis',
        'mdm166a',
        'ms6931',
        'mtc_s16209x',
        'mx5000',
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
        'xosd',
        'yard2LCD'
      ]
    },
    'license' => 'GPL-2',
    'name' => 'LCDd',
    'rw_config' => {
      'backend' => 'IniFile',
      'config_dir' => '/etc',
      'file' => 'LCDd.conf',
      'quote_value' => 'shell_style'
    },
    'warp' => {
      'CFontz' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'CFontz\')'
          }
        ]
      },
      'CFontzPacket' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'CFontzPacket\')'
          }
        ]
      },
      'CwLnx' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'CwLnx\')'
          }
        ]
      },
      'EyeboxOne' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'EyeboxOne\')'
          }
        ]
      },
      'IOWarrior' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'IOWarrior\')'
          }
        ]
      },
      'IrMan' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'IrMan\')'
          }
        ]
      },
      'MD8800' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'MD8800\')'
          }
        ]
      },
      'MtxOrb' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'MtxOrb\')'
          }
        ]
      },
      'NoritakeVFD' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'NoritakeVFD\')'
          }
        ]
      },
      'Olimex_MOD_LCD1x9' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'Olimex_MOD_LCD1x9\')'
          }
        ]
      },
      'SureElec' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'SureElec\')'
          }
        ]
      },
      'bayrad' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'bayrad\')'
          }
        ]
      },
      'curses' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'curses\')'
          }
        ]
      },
      'ea65' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'ea65\')'
          }
        ]
      },
      'futaba' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'futaba\')'
          }
        ]
      },
      'g15' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'g15\')'
          }
        ]
      },
      'glcd' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'glcd\')'
          }
        ]
      },
      'glcdlib' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'glcdlib\')'
          }
        ]
      },
      'glk' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'glk\')'
          }
        ]
      },
      'hd44780' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'hd44780\')'
          }
        ]
      },
      'icp_a106' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'icp_a106\')'
          }
        ]
      },
      'imon' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'imon\')'
          }
        ]
      },
      'imonlcd' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'imonlcd\')'
          }
        ]
      },
      'irtrans' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'irtrans\')'
          }
        ]
      },
      'joy' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'joy\')'
          }
        ]
      },
      'lb216' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'lb216\')'
          }
        ]
      },
      'lcdm001' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'lcdm001\')'
          }
        ]
      },
      'lcterm' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'lcterm\')'
          }
        ]
      },
      'linux_input' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'linux_input\')'
          }
        ]
      },
      'lirc' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'lirc\')'
          }
        ]
      },
      'lis' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'lis\')'
          }
        ]
      },
      'mdm166a' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'mdm166a\')'
          }
        ]
      },
      'ms6931' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'ms6931\')'
          }
        ]
      },
      'mtc_s16209x' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'mtc_s16209x\')'
          }
        ]
      },
      'mx5000' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'mx5000\')'
          }
        ]
      },
      'picolcd' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'picolcd\')'
          }
        ]
      },
      'pyramid' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'pyramid\')'
          }
        ]
      },
      'rawserial' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'rawserial\')'
          }
        ]
      },
      'sdeclcd' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'sdeclcd\')'
          }
        ]
      },
      'sed1330' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'sed1330\')'
          }
        ]
      },
      'sed1520' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'sed1520\')'
          }
        ]
      },
      'serialPOS' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'serialPOS\')'
          }
        ]
      },
      'serialVFD' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'serialVFD\')'
          }
        ]
      },
      'shuttleVFD' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'shuttleVFD\')'
          }
        ]
      },
      'sli' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'sli\')'
          }
        ]
      },
      'stv5730' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'stv5730\')'
          }
        ]
      },
      'svga' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'svga\')'
          }
        ]
      },
      't6963' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'t6963\')'
          }
        ]
      },
      'text' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'text\')'
          }
        ]
      },
      'tyan' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'tyan\')'
          }
        ]
      },
      'ula200' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'ula200\')'
          }
        ]
      },
      'vlsys_m428' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'vlsys_m428\')'
          }
        ]
      },
      'xosd' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'xosd\')'
          }
        ]
      },
      'yard2LCD' => {
        'follow' => {
          'selected' => '- server Driver'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'normal'
            },
            'when' => '$selected.is_set(\'yard2LCD\')'
          }
        ]
      }
    }
  }
]
;
