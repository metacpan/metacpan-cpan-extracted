#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
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
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'CFontz\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'CFontzPacket',
      {
        'config_class_name' => 'LCDd::CFontzPacket',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'CFontzPacket\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'CwLnx',
      {
        'config_class_name' => 'LCDd::CwLnx',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'CwLnx\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'EyeboxOne',
      {
        'config_class_name' => 'LCDd::EyeboxOne',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'EyeboxOne\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'IOWarrior',
      {
        'config_class_name' => 'LCDd::IOWarrior',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'IOWarrior\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'IrMan',
      {
        'config_class_name' => 'LCDd::IrMan',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'IrMan\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'MD8800',
      {
        'config_class_name' => 'LCDd::MD8800',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'MD8800\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'MtxOrb',
      {
        'config_class_name' => 'LCDd::MtxOrb',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'MtxOrb\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'NoritakeVFD',
      {
        'config_class_name' => 'LCDd::NoritakeVFD',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'NoritakeVFD\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'Olimex_MOD_LCD1x9',
      {
        'config_class_name' => 'LCDd::Olimex_MOD_LCD1x9',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'Olimex_MOD_LCD1x9\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'SureElec',
      {
        'config_class_name' => 'LCDd::SureElec',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'SureElec\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'bayrad',
      {
        'config_class_name' => 'LCDd::bayrad',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'bayrad\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'curses',
      {
        'config_class_name' => 'LCDd::curses',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'curses\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'ea65',
      {
        'config_class_name' => 'LCDd::ea65',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'ea65\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'futaba',
      {
        'config_class_name' => 'LCDd::futaba',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'futaba\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'g15',
      {
        'config_class_name' => 'LCDd::g15',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'g15\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'glcd',
      {
        'config_class_name' => 'LCDd::glcd',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'glcd\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'glcdlib',
      {
        'config_class_name' => 'LCDd::glcdlib',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'glcdlib\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'glk',
      {
        'config_class_name' => 'LCDd::glk',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'glk\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'hd44780',
      {
        'config_class_name' => 'LCDd::hd44780',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'hd44780\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'icp_a106',
      {
        'config_class_name' => 'LCDd::icp_a106',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'icp_a106\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'imon',
      {
        'config_class_name' => 'LCDd::imon',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'imon\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'imonlcd',
      {
        'config_class_name' => 'LCDd::imonlcd',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'imonlcd\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'irtrans',
      {
        'config_class_name' => 'LCDd::irtrans',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'irtrans\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'joy',
      {
        'config_class_name' => 'LCDd::joy',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'joy\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'lb216',
      {
        'config_class_name' => 'LCDd::lb216',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'lb216\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'lcdm001',
      {
        'config_class_name' => 'LCDd::lcdm001',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'lcdm001\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'lcterm',
      {
        'config_class_name' => 'LCDd::lcterm',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'lcterm\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'linux_input',
      {
        'config_class_name' => 'LCDd::linux_input',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'linux_input\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'lirc',
      {
        'config_class_name' => 'LCDd::lirc',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'lirc\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'lis',
      {
        'config_class_name' => 'LCDd::lis',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'lis\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'mdm166a',
      {
        'config_class_name' => 'LCDd::mdm166a',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'mdm166a\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'menu',
      {
        'config_class_name' => 'LCDd::menu',
        'type' => 'node'
      },
      'ms6931',
      {
        'config_class_name' => 'LCDd::ms6931',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'ms6931\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'mtc_s16209x',
      {
        'config_class_name' => 'LCDd::mtc_s16209x',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'mtc_s16209x\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'mx5000',
      {
        'config_class_name' => 'LCDd::mx5000',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'mx5000\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'picolcd',
      {
        'config_class_name' => 'LCDd::picolcd',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'picolcd\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'pyramid',
      {
        'config_class_name' => 'LCDd::pyramid',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'pyramid\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'rawserial',
      {
        'config_class_name' => 'LCDd::rawserial',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'rawserial\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'sdeclcd',
      {
        'config_class_name' => 'LCDd::sdeclcd',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'sdeclcd\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'sed1330',
      {
        'config_class_name' => 'LCDd::sed1330',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'sed1330\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'sed1520',
      {
        'config_class_name' => 'LCDd::sed1520',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'sed1520\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'serialPOS',
      {
        'config_class_name' => 'LCDd::serialPOS',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'serialPOS\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'serialVFD',
      {
        'config_class_name' => 'LCDd::serialVFD',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'serialVFD\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'shuttleVFD',
      {
        'config_class_name' => 'LCDd::shuttleVFD',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'shuttleVFD\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'sli',
      {
        'config_class_name' => 'LCDd::sli',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'sli\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'stv5730',
      {
        'config_class_name' => 'LCDd::stv5730',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'stv5730\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'svga',
      {
        'config_class_name' => 'LCDd::svga',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'svga\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      't6963',
      {
        'config_class_name' => 'LCDd::t6963',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'t6963\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'text',
      {
        'config_class_name' => 'LCDd::text',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'text\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'tyan',
      {
        'config_class_name' => 'LCDd::tyan',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'tyan\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'ula200',
      {
        'config_class_name' => 'LCDd::ula200',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'ula200\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'vlsys_m428',
      {
        'config_class_name' => 'LCDd::vlsys_m428',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'vlsys_m428\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'xosd',
      {
        'config_class_name' => 'LCDd::xosd',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'xosd\')',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'yard2LCD',
      {
        'config_class_name' => 'LCDd::yard2LCD',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'selected' => '- server Driver'
          },
          'rules' => [
            '$selected.is_set(\'yard2LCD\')',
            {
              'level' => 'normal'
            }
          ]
        }
      }
    ],
    'license' => 'GPL-2',
    'name' => 'LCDd',
    'rw_config' => {
      'backend' => 'IniFile',
      'config_dir' => '/etc',
      'file' => 'LCDd.conf'
    }
  }
]
;

