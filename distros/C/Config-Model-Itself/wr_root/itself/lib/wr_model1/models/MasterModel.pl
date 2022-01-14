# -*- cperl -*-
#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

# this file is used by test script

use strict;
use warnings;

return [
  {
    'element' => [
      'aa2',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'ab2',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'ac2',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'ad2',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'Z',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      }
    ],
    'name' => 'MasterModel::SubSlave2'
  },
  {
    'element' => [
      'aa',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'ab',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'ac',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'ad',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'sub_slave',
      {
        'config_class_name' => 'MasterModel::SubSlave2',
        'type' => 'node'
      }
    ],
    'name' => 'MasterModel::SubSlave'
  },
  {
    'element' => [
      'Z',
      {
        'choice' => [
          'Av',
          'Bv',
          'Cv'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'DX',
      {
        'choice' => [
          'Av',
          'Bv',
          'Cv',
          'Dv'
        ],
        'default' => 'Dv',
        'type' => 'leaf',
        'value_type' => 'enum'
      }
    ],
    'include' => [
      'MasterModel::X_base_class'
    ],
    'name' => 'MasterModel::SlaveZ'
  },
  {
    'element' => [
      'std_id',
      {
        'cargo' => {
          'config_class_name' => 'MasterModel::SlaveZ',
          'type' => 'node'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'sub_slave',
      {
        'config_class_name' => 'MasterModel::SubSlave',
        'type' => 'node'
      },
      'warp2',
      {
        'config_class_name' => 'MasterModel::SubSlave',
        'morph' => 1,
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'f1' => '! tree_macro'
          },
          'rules' => [
            '$f1 eq \'mXY\'',
            {
              'config_class_name' => 'MasterModel::SubSlave2'
            },
            '$f1 eq \'XZ\'',
            {
              'config_class_name' => 'MasterModel::SubSlave2'
            }
          ]
        }
      },
      'Y',
      {
        'choice' => [
          'Av',
          'Bv',
          'Cv'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      }
    ],
    'include' => [
      'MasterModel::X_base_class'
    ],
    'name' => 'MasterModel::SlaveY'
  },
  {
    'accept' => [
      'list.*',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'type' => 'list'
      },
      'str.*',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'element' => [
      'id',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'MasterModel::TolerantNode'
  },
  {
    'author' => [
      'dod@foo.com'
    ],
    'class_description' => 'Master description',
    'copyright' => [
      '2011 dod'
    ],
    'element' => [
      'std_id',
      {
        'cargo' => {
          'config_class_name' => 'MasterModel::SlaveZ',
          'type' => 'node'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'integer_with_warn_if',
      {
        'type' => 'leaf',
        'value_type' => 'integer',
        'warn_if' => {
          'warn_test' => {
            'code' => 'defined $_ && $_ < 9;',
            'fix' => '$_ = 10;',
            'msg' => 'should be greater than 9'
          }
        }
      },
      'lista',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'type' => 'list'
      },
      'listb',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'type' => 'list'
      },
      'ac_list',
      {
        'auto_create_ids' => 3,
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'type' => 'list'
      },
      'list_XLeds',
      {
        'cargo' => {
          'max' => 3,
          'min' => 1,
          'type' => 'leaf',
          'value_type' => 'integer'
        },
        'type' => 'list'
      },
      'hash_a',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'index_type' => 'string',
        'level' => 'important',
        'type' => 'hash'
      },
      'hash_b',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'olist',
      {
        'cargo' => {
          'config_class_name' => 'MasterModel::SlaveZ',
          'type' => 'node'
        },
        'type' => 'list'
      },
      'tree_macro',
      {
        'choice' => [
          'XY',
          'XZ',
          'mXY'
        ],
        'description' => 'controls behavior of other elements',
        'help' => {
          'XY' => 'XY help',
          'XZ' => 'XZ help',
          'mXY' => 'mXY help'
        },
        'level' => 'important',
        'summary' => 'macro parameter for tree',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'warp_el',
      {
        'config_class_name' => 'MasterModel::SlaveY',
        'morph' => 1,
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'f1' => '! tree_macro'
          },
          'rules' => [
            '$f1 eq \'mXY\'',
            {
              'config_class_name' => 'MasterModel::SlaveY'
            },
            '$f1 eq \'XZ\'',
            {
              'config_class_name' => 'MasterModel::SlaveZ'
            }
          ]
        }
      },
      'tolerant_node',
      {
        'config_class_name' => 'MasterModel::TolerantNode',
        'type' => 'node'
      },
      'slave_y',
      {
        'config_class_name' => 'MasterModel::SlaveY',
        'type' => 'node'
      },
      'string_with_def',
      {
        'default' => 'yada yada',
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'a_string',
      {
        'mandatory' => 1,
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'int_v',
      {
        'default' => '10',
        'level' => 'important',
        'max' => 15,
        'min' => 5,
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'my_check_list',
      {
        'refer_to' => '- hash_a + ! hash_b',
        'type' => 'check_list'
      },
      'ordered_checklist',
      {
        'choice' => [
          'A',
          'B',
          'C',
          'D',
          'E',
          'F',
          'G',
          'H',
          'I',
          'J',
          'K',
          'L',
          'M',
          'N',
          'O',
          'P',
          'Q',
          'R',
          'S',
          'T',
          'U',
          'V',
          'W',
          'X',
          'Y',
          'Z'
        ],
        'help' => {
          'A' => 'A help',
          'E' => 'E help'
        },
        'ordered' => 1,
        'type' => 'check_list'
      },
      'my_reference',
      {
        'refer_to' => '- hash_a + ! hash_b',
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'lot_of_checklist',
      {
        'config_class_name' => 'MasterModel::CheckListExamples',
        'type' => 'node'
      },
      'warped_values',
      {
        'config_class_name' => 'MasterModel::WarpedValues',
        'type' => 'node'
      },
      'warped_id',
      {
        'config_class_name' => 'MasterModel::WarpedId',
        'type' => 'node'
      },
      'hash_id_of_values',
      {
        'config_class_name' => 'MasterModel::HashIdOfValues',
        'type' => 'node'
      },
      'deprecated_p',
      {
        'choice' => [
          'cds',
          'perl',
          'ini',
          'custom'
        ],
        'description' => 'deprecated_p is replaced by new_from_deprecated',
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'new_from_deprecated',
      {
        'choice' => [
          'cds_file',
          'perl_file',
          'ini_file',
          'custom'
        ],
        'migrate_from' => {
          'formula' => '$replace{$old}',
          'replace' => {
            'cds' => 'cds_file',
            'ini' => 'ini_file',
            'perl' => 'perl_file'
          },
          'variables' => {
            'old' => '- deprecated_p'
          }
        },
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'old_url',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'host',
      {
        'migrate_from' => {
          'formula' => '$old =~ m!http://([\\w\\.]+)!; $1 ;',
          'use_eval' => 1,
          'variables' => {
            'old' => '- old_url'
          }
        },
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'reference_stuff',
      {
        'config_class_name' => 'MasterModel::References',
        'type' => 'node'
      },
      'match',
      {
        'match' => '^foo\\d{2}$',
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'prd_match',
      {
        'grammar' => 'token (oper token)(s?)
                                            oper: \'and\' | \'or\'
                                            token: \'Apache\' | \'CC-BY\' | \'Perl\'
                                           ',
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'warn_if',
      {
        'type' => 'leaf',
        'value_type' => 'string',
        'warn_if_match' => {
          'foo' => {
            'fix' => '$_ = uc;'
          }
        }
      },
      'warn_unless',
      {
        'type' => 'leaf',
        'value_type' => 'string',
        'warn_unless_match' => {
          'foo' => {
            'fix' => '$_ = "foo".$_;'
          }
        }
      },
      'list_with_migrate_values_from',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'migrate_values_from' => '- lista',
        'type' => 'list'
      },
      'hash_with_migrate_keys_from',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'index_type' => 'string',
        'migrate_keys_from' => '- hash_a',
        'type' => 'hash'
      },
      'assert_leaf',
      {
        'assert' => {
          'assert_test' => {
            'code' => 'defined $_ and /\\w/',
            'fix' => '$_ = "foobar";',
            'msg' => 'must not be empty'
          }
        },
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'leaf_with_warn_unless',
      {
        'type' => 'leaf',
        'value_type' => 'string',
        'warn_unless' => {
          'warn_test' => {
            'code' => 'defined $_ and /\\w/',
            'fix' => '$_ = "foobar";',
            'msg' => 'should not be empty'
          }
        }
      },
      'Source',
      {
        'migrate_from' => {
          'formula' => '$old || $older ;',
          'undef_is' => '\'\'',
          'use_eval' => '1',
          'variables' => {
            'old' => '- Upstream-Source',
            'older' => '- Original-Source-Location'
          }
        },
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'Upstream-Source',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'Original-Source-Location',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'list_with_warn_duplicates',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'duplicates' => 'warn',
        'type' => 'list'
      },
      'list_with_allow_duplicates',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'type' => 'list'
      },
      'list_with_forbid_duplicates',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'duplicates' => 'forbid',
        'type' => 'list'
      },
      'list_with_suppress_duplicates',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'duplicates' => 'suppress',
        'type' => 'list'
      }
    ],
    'license' => 'LGPL',
    'name' => 'MasterModel',
    'rw_config' => {
      'auto_create' => 1,
      'backend' => 'cds_file',
      'config_dir' => 'conf_data',
      'file' => 'mymaster.cds'
    }
  }
]
;






