#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
$VAR1 = {
          'class' => [
                       'MasterModel',
                       {
                         'element' => [
                                        'std_id',
                                        {
                                          'type' => 'hash',
                                          'cargo' => {
                                                       'config_class_name' => 'MasterModel::SlaveZ',
                                                       'type' => 'node'
                                                     },
                                          'index_type' => 'string'
                                        },
                                        'integer_with_warn_if',
                                        {
                                          'type' => 'leaf',
                                          'value_type' => 'integer',
                                          'warn_if' => {
                                                         'warn_test' => {
                                                                          'msg' => 'should be greater than 9',
                                                                          'code' => 'defined $_ && $_ < 9;',
                                                                          'fix' => '$_ = 10;'
                                                                        }
                                                       }
                                        },
                                        'lista',
                                        {
                                          'type' => 'list',
                                          'cargo' => {
                                                       'type' => 'leaf',
                                                       'value_type' => 'string'
                                                     }
                                        },
                                        'listb',
                                        {
                                          'cargo' => {
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
                                                     },
                                          'type' => 'list'
                                        },
                                        'ac_list',
                                        {
                                          'cargo' => {
                                                       'type' => 'leaf',
                                                       'value_type' => 'string'
                                                     },
                                          'auto_create_ids' => '3',
                                          'type' => 'list'
                                        },
                                        'list_XLeds',
                                        {
                                          'cargo' => {
                                                       'value_type' => 'integer',
                                                       'type' => 'leaf',
                                                       'max' => '3',
                                                       'min' => '1'
                                                     },
                                          'type' => 'list'
                                        },
                                        'hash_a',
                                        {
                                          'level' => 'important',
                                          'index_type' => 'string',
                                          'cargo' => {
                                                       'type' => 'leaf',
                                                       'value_type' => 'string'
                                                     },
                                          'type' => 'hash'
                                        },
                                        'hash_b',
                                        {
                                          'type' => 'hash',
                                          'index_type' => 'string',
                                          'cargo' => {
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
                                                     }
                                        },
                                        'olist',
                                        {
                                          'type' => 'list',
                                          'cargo' => {
                                                       'config_class_name' => 'MasterModel::SlaveZ',
                                                       'type' => 'node'
                                                     }
                                        },
                                        'tree_macro',
                                        {
                                          'summary' => 'macro parameter for tree',
                                          'help' => {
                                                      'XY' => 'XY help',
                                                      'XZ' => 'XZ help',
                                                      'mXY' => 'mXY help'
                                                    },
                                          'level' => 'important',
                                          'choice' => [
                                                        'XY',
                                                        'XZ',
                                                        'mXY'
                                                      ],
                                          'description' => 'controls behavior of other elements',
                                          'value_type' => 'enum',
                                          'type' => 'leaf'
                                        },
                                        'warp_el',
                                        {
                                          'warp' => {
                                                      'rules' => [
                                                                   '$f1 eq \'mXY\'',
                                                                   {
                                                                     'config_class_name' => 'MasterModel::SlaveY'
                                                                   },
                                                                   '$f1 eq \'XZ\'',
                                                                   {
                                                                     'config_class_name' => 'MasterModel::SlaveZ'
                                                                   }
                                                                 ],
                                                      'follow' => {
                                                                    'f1' => '! tree_macro'
                                                                  }
                                                    },
                                          'config_class_name' => 'MasterModel::SlaveY',
                                          'morph' => '1',
                                          'type' => 'warped_node'
                                        },
                                        'tolerant_node',
                                        {
                                          'type' => 'node',
                                          'config_class_name' => 'MasterModel::TolerantNode'
                                        },
                                        'slave_y',
                                        {
                                          'type' => 'node',
                                          'config_class_name' => 'MasterModel::SlaveY'
                                        },
                                        'string_with_def',
                                        {
                                          'type' => 'leaf',
                                          'value_type' => 'string',
                                          'default' => 'yada yada'
                                        },
                                        'a_string',
                                        {
                                          'mandatory' => '1',
                                          'type' => 'leaf',
                                          'value_type' => 'string'
                                        },
                                        'int_v',
                                        {
                                          'level' => 'important',
                                          'max' => '15',
                                          'min' => '5',
                                          'type' => 'leaf',
                                          'default' => '10',
                                          'value_type' => 'integer'
                                        },
                                        'my_check_list',
                                        {
                                          'refer_to' => '- hash_a + ! hash_b',
                                          'type' => 'check_list'
                                        },
                                        'ordered_checklist',
                                        {
                                          'type' => 'check_list',
                                          'ordered' => '1',
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
                                                      'E' => 'E help',
                                                      'A' => 'A help'
                                                    }
                                        },
                                        'my_reference',
                                        {
                                          'refer_to' => '- hash_a + ! hash_b',
                                          'value_type' => 'reference',
                                          'type' => 'leaf'
                                        },
                                        'lot_of_checklist',
                                        {
                                          'type' => 'node',
                                          'config_class_name' => 'MasterModel::CheckListExamples'
                                        },
                                        'warped_values',
                                        {
                                          'type' => 'node',
                                          'config_class_name' => 'MasterModel::WarpedValues'
                                        },
                                        'warped_id',
                                        {
                                          'config_class_name' => 'MasterModel::WarpedId',
                                          'type' => 'node'
                                        },
                                        'hash_id_of_values',
                                        {
                                          'type' => 'node',
                                          'config_class_name' => 'MasterModel::HashIdOfValues'
                                        },
                                        'deprecated_p',
                                        {
                                          'description' => 'deprecated_p is replaced by new_from_deprecated',
                                          'value_type' => 'enum',
                                          'type' => 'leaf',
                                          'status' => 'deprecated',
                                          'choice' => [
                                                        'cds',
                                                        'perl',
                                                        'ini',
                                                        'custom'
                                                      ]
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
                                                              'replace' => {
                                                                             'cds' => 'cds_file',
                                                                             'perl' => 'perl_file',
                                                                             'ini' => 'ini_file'
                                                                           },
                                                              'variables' => {
                                                                               'old' => '- deprecated_p'
                                                                             },
                                                              'formula' => '$replace{$old}'
                                                            },
                                          'type' => 'leaf',
                                          'value_type' => 'enum'
                                        },
                                        'old_url',
                                        {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf',
                                          'status' => 'deprecated'
                                        },
                                        'host',
                                        {
                                          'type' => 'leaf',
                                          'value_type' => 'uniline',
                                          'migrate_from' => {
                                                              'formula' => '$old =~ m!http://([\\w\\.]+)!; $1 ;',
                                                              'use_eval' => '1',
                                                              'variables' => {
                                                                               'old' => '- old_url'
                                                                             }
                                                            }
                                        },
                                        'reference_stuff',
                                        {
                                          'type' => 'node',
                                          'config_class_name' => 'MasterModel::References'
                                        },
                                        'match',
                                        {
                                          'match' => '^foo\\d{2}$',
                                          'value_type' => 'string',
                                          'type' => 'leaf'
                                        },
                                        'prd_match',
                                        {
                                          'value_type' => 'string',
                                          'grammar' => 'token (oper token)(s?)
                                            oper: \'and\' | \'or\'
                                            token: \'Apache\' | \'CC-BY\' | \'Perl\'
                                           ',
                                          'type' => 'leaf'
                                        },
                                        'warn_if',
                                        {
                                          'value_type' => 'string',
                                          'type' => 'leaf',
                                          'warn_if_match' => {
                                                               'foo' => {
                                                                          'fix' => '$_ = uc;'
                                                                        }
                                                             }
                                        },
                                        'warn_unless',
                                        {
                                          'value_type' => 'string',
                                          'warn_unless_match' => {
                                                                   'foo' => {
                                                                              'fix' => '$_ = "foo".$_;'
                                                                            }
                                                                 },
                                          'type' => 'leaf'
                                        },
                                        'list_with_migrate_values_from',
                                        {
                                          'type' => 'list',
                                          'migrate_values_from' => '- lista',
                                          'cargo' => {
                                                       'type' => 'leaf',
                                                       'value_type' => 'string'
                                                     }
                                        },
                                        'hash_with_migrate_keys_from',
                                        {
                                          'type' => 'hash',
                                          'migrate_keys_from' => '- hash_a',
                                          'index_type' => 'string',
                                          'cargo' => {
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
                                                     }
                                        },
                                        'assert_leaf',
                                        {
                                          'assert' => {
                                                        'assert_test' => {
                                                                           'msg' => 'must not be empty',
                                                                           'code' => 'defined $_ and /\\w/',
                                                                           'fix' => '$_ = "foobar";'
                                                                         }
                                                      },
                                          'type' => 'leaf',
                                          'value_type' => 'string'
                                        },
                                        'leaf_with_warn_unless',
                                        {
                                          'value_type' => 'string',
                                          'type' => 'leaf',
                                          'warn_unless' => {
                                                             'warn_test' => {
                                                                              'msg' => 'should not be empty',
                                                                              'code' => 'defined $_ and /\\w/',
                                                                              'fix' => '$_ = "foobar";'
                                                                            }
                                                           }
                                        },
                                        'Source',
                                        {
                                          'value_type' => 'string',
                                          'type' => 'leaf',
                                          'migrate_from' => {
                                                              'formula' => '$old || $older ;',
                                                              'undef_is' => '\'\'',
                                                              'use_eval' => '1',
                                                              'variables' => {
                                                                               'older' => '- Original-Source-Location',
                                                                               'old' => '- Upstream-Source'
                                                                             }
                                                            }
                                        },
                                        'Upstream-Source',
                                        {
                                          'value_type' => 'string',
                                          'type' => 'leaf',
                                          'status' => 'deprecated'
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
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
                                                     },
                                          'duplicates' => 'warn',
                                          'type' => 'list'
                                        },
                                        'list_with_allow_duplicates',
                                        {
                                          'cargo' => {
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
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
                                          'duplicates' => 'suppress',
                                          'cargo' => {
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
                                                     },
                                          'type' => 'list'
                                        }
                                      ],
                         'author' => [
                                       'dod@foo.com'
                                     ],
                         'rw_config' => {
                                          'config_dir' => 'conf_data',
                                          'backend' => 'cds_file',
                                          'file' => 'mymaster.cds',
                                          'auto_create' => '1'
                                        },
                         'copyright' => [
                                          '2011 dod'
                                        ],
                         'class_description' => 'Master description',
                         'license' => 'LGPL'
                       },
                       'MasterModel::CheckListExamples',
                       {
                         'element' => [
                                        'my_hash',
                                        {
                                          'index_type' => 'string',
                                          'cargo' => {
                                                       'type' => 'leaf',
                                                       'value_type' => 'string'
                                                     },
                                          'type' => 'hash'
                                        },
                                        'my_hash2',
                                        {
                                          'cargo' => {
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
                                                     },
                                          'index_type' => 'string',
                                          'type' => 'hash'
                                        },
                                        'my_hash3',
                                        {
                                          'cargo' => {
                                                       'type' => 'leaf',
                                                       'value_type' => 'string'
                                                     },
                                          'index_type' => 'string',
                                          'type' => 'hash'
                                        },
                                        'choice_list',
                                        {
                                          'type' => 'check_list',
                                          'help' => {
                                                      'E' => 'E help',
                                                      'A' => 'A help'
                                                    },
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
                                                      ]
                                        },
                                        'choice_list_with_default',
                                        {
                                          'type' => 'check_list',
                                          'default_list' => [
                                                              'A',
                                                              'D'
                                                            ],
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
                                                    }
                                        },
                                        'choice_list_with_upstream_default_list',
                                        {
                                          'help' => {
                                                      'A' => 'A help',
                                                      'E' => 'E help'
                                                    },
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
                                          'upstream_default_list' => [
                                                                       'A',
                                                                       'D'
                                                                     ],
                                          'type' => 'check_list'
                                        },
                                        'macro',
                                        {
                                          'choice' => [
                                                        'AD',
                                                        'AH'
                                                      ],
                                          'value_type' => 'enum',
                                          'type' => 'leaf'
                                        },
                                        'warped_choice_list',
                                        {
                                          'type' => 'check_list',
                                          'warp' => {
                                                      'follow' => {
                                                                    'f1' => '- macro'
                                                                  },
                                                      'rules' => [
                                                                   '$f1 eq \'AH\'',
                                                                   {
                                                                     'choice' => [
                                                                                   'A',
                                                                                   'B',
                                                                                   'C',
                                                                                   'D',
                                                                                   'E',
                                                                                   'F',
                                                                                   'G',
                                                                                   'H'
                                                                                 ]
                                                                   },
                                                                   '$f1 eq \'AD\'',
                                                                   {
                                                                     'choice' => [
                                                                                   'A',
                                                                                   'B',
                                                                                   'C',
                                                                                   'D'
                                                                                 ],
                                                                     'default_list' => [
                                                                                         'A',
                                                                                         'B'
                                                                                       ]
                                                                   }
                                                                 ]
                                                    }
                                        },
                                        'refer_to_list',
                                        {
                                          'refer_to' => '- my_hash',
                                          'type' => 'check_list'
                                        },
                                        'refer_to_2_list',
                                        {
                                          'type' => 'check_list',
                                          'refer_to' => '- my_hash + - my_hash2   + - my_hash3'
                                        },
                                        'refer_to_check_list_and_choice',
                                        {
                                          'type' => 'check_list',
                                          'computed_refer_to' => {
                                                                   'variables' => {
                                                                                    'var' => '- indirection '
                                                                                  },
                                                                   'formula' => '- refer_to_2_list + - $var'
                                                                 },
                                          'choice' => [
                                                        'A1',
                                                        'A2',
                                                        'A3'
                                                      ]
                                        },
                                        'indirection',
                                        {
                                          'value_type' => 'string',
                                          'type' => 'leaf'
                                        }
                                      ]
                       },
                       'MasterModel::HashIdOfValues',
                       {
                         'element' => [
                                        'plain_hash',
                                        {
                                          'type' => 'hash',
                                          'index_type' => 'integer',
                                          'cargo' => {
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
                                                     }
                                        },
                                        'hash_with_auto_created_id',
                                        {
                                          'type' => 'hash',
                                          'cargo' => {
                                                       'type' => 'leaf',
                                                       'value_type' => 'string'
                                                     },
                                          'auto_create_keys' => [
                                                                  'yada'
                                                                ],
                                          'index_type' => 'string'
                                        },
                                        'hash_with_several_auto_created_id',
                                        {
                                          'index_type' => 'string',
                                          'cargo' => {
                                                       'type' => 'leaf',
                                                       'value_type' => 'string'
                                                     },
                                          'auto_create_keys' => [
                                                                  'x',
                                                                  'y',
                                                                  'z'
                                                                ],
                                          'type' => 'hash'
                                        },
                                        'hash_with_default_id',
                                        {
                                          'index_type' => 'string',
                                          'cargo' => {
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
                                                     },
                                          'default_keys' => [
                                                              'yada'
                                                            ],
                                          'type' => 'hash'
                                        },
                                        'hash_with_default_id_2',
                                        {
                                          'type' => 'hash',
                                          'default_keys' => [
                                                              'yada'
                                                            ],
                                          'cargo' => {
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
                                                     },
                                          'index_type' => 'string'
                                        },
                                        'hash_with_several_default_keys',
                                        {
                                          'default_keys' => [
                                                              'x',
                                                              'y',
                                                              'z'
                                                            ],
                                          'cargo' => {
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
                                                     },
                                          'index_type' => 'string',
                                          'type' => 'hash'
                                        },
                                        'hash_follower',
                                        {
                                          'cargo' => {
                                                       'type' => 'leaf',
                                                       'value_type' => 'string'
                                                     },
                                          'index_type' => 'string',
                                          'follow_keys_from' => '- hash_with_several_auto_created_id',
                                          'type' => 'hash'
                                        },
                                        'hash_with_allow',
                                        {
                                          'type' => 'hash',
                                          'allow_keys' => [
                                                            'foo',
                                                            'bar',
                                                            'baz'
                                                          ],
                                          'cargo' => {
                                                       'type' => 'leaf',
                                                       'value_type' => 'string'
                                                     },
                                          'index_type' => 'string'
                                        },
                                        'hash_with_allow_from',
                                        {
                                          'allow_keys_from' => '- hash_with_several_auto_created_id',
                                          'cargo' => {
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
                                                     },
                                          'index_type' => 'string',
                                          'type' => 'hash'
                                        },
                                        'ordered_hash',
                                        {
                                          'index_type' => 'string',
                                          'cargo' => {
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
                                                     },
                                          'type' => 'hash',
                                          'ordered' => '1'
                                        }
                                      ]
                       },
                       'MasterModel::RSlave',
                       {
                         'element' => [
                                        'recursive_slave',
                                        {
                                          'type' => 'hash',
                                          'cargo' => {
                                                       'type' => 'node',
                                                       'config_class_name' => 'MasterModel::RSlave'
                                                     },
                                          'index_type' => 'string'
                                        },
                                        'big_compute',
                                        {
                                          'type' => 'hash',
                                          'index_type' => 'string',
                                          'cargo' => {
                                                       'compute' => {
                                                                      'formula' => 'macro is $m, my idx: &index, my element &element, upper element &element($up), up idx &index($up)',
                                                                      'variables' => {
                                                                                       'm' => '!  macro',
                                                                                       'up' => '-'
                                                                                     }
                                                                    },
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
                                                     }
                                        },
                                        'big_replace',
                                        {
                                          'compute' => {
                                                         'variables' => {
                                                                          'up' => '-'
                                                                        },
                                                         'replace' => {
                                                                        'l1' => 'level1',
                                                                        'l2' => 'level2'
                                                                      },
                                                         'formula' => 'trad idx $replace{&index($up)}'
                                                       },
                                          'value_type' => 'string',
                                          'type' => 'leaf'
                                        },
                                        'macro_replace',
                                        {
                                          'type' => 'hash',
                                          'index_type' => 'string',
                                          'cargo' => {
                                                       'compute' => {
                                                                      'formula' => 'trad macro is $replace{$m}',
                                                                      'replace' => {
                                                                                     'B' => 'macroB',
                                                                                     'A' => 'macroA',
                                                                                     'C' => 'macroC'
                                                                                   },
                                                                      'variables' => {
                                                                                       'm' => '!  macro'
                                                                                     }
                                                                    },
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
                                                     }
                                        }
                                      ]
                       },
                       'MasterModel::References',
                       {
                         'element' => [
                                        'host',
                                        {
                                          'type' => 'hash',
                                          'cargo' => {
                                                       'config_class_name' => 'MasterModel::References::Host',
                                                       'type' => 'node'
                                                     },
                                          'index_type' => 'string'
                                        },
                                        'lan',
                                        {
                                          'type' => 'hash',
                                          'index_type' => 'string',
                                          'cargo' => {
                                                       'config_class_name' => 'MasterModel::References::Lan',
                                                       'type' => 'node'
                                                     }
                                        },
                                        'host_and_choice',
                                        {
                                          'computed_refer_to' => {
                                                                   'formula' => '- host '
                                                                 },
                                          'choice' => [
                                                        'foo',
                                                        'bar'
                                                      ],
                                          'value_type' => 'reference',
                                          'type' => 'leaf'
                                        },
                                        'dumb_list',
                                        {
                                          'cargo' => {
                                                       'value_type' => 'string',
                                                       'type' => 'leaf'
                                                     },
                                          'type' => 'list'
                                        },
                                        'refer_to_list_enum',
                                        {
                                          'type' => 'leaf',
                                          'value_type' => 'reference',
                                          'refer_to' => '- dumb_list'
                                        }
                                      ]
                       },
                       'MasterModel::References::Host',
                       {
                         'element' => [
                                        'if',
                                        {
                                          'cargo' => {
                                                       'config_class_name' => 'MasterModel::References::If',
                                                       'type' => 'node'
                                                     },
                                          'index_type' => 'string',
                                          'type' => 'hash'
                                        },
                                        'trap',
                                        {
                                          'type' => 'leaf',
                                          'value_type' => 'string'
                                        }
                                      ]
                       },
                       'MasterModel::References::If',
                       {
                         'element' => [
                                        'ip',
                                        {
                                          'type' => 'leaf',
                                          'value_type' => 'string'
                                        }
                                      ]
                       },
                       'MasterModel::References::Lan',
                       {
                         'element' => [
                                        'node',
                                        {
                                          'index_type' => 'string',
                                          'cargo' => {
                                                       'type' => 'node',
                                                       'config_class_name' => 'MasterModel::References::Node'
                                                     },
                                          'type' => 'hash'
                                        }
                                      ]
                       },
                       'MasterModel::References::Node',
                       {
                         'element' => [
                                        'host',
                                        {
                                          'type' => 'leaf',
                                          'value_type' => 'reference',
                                          'refer_to' => '- host'
                                        },
                                        'if',
                                        {
                                          'type' => 'leaf',
                                          'value_type' => 'reference',
                                          'computed_refer_to' => {
                                                                   'variables' => {
                                                                                    'h' => '- host'
                                                                                  },
                                                                   'formula' => '  - host:$h if '
                                                                 }
                                        },
                                        'ip',
                                        {
                                          'compute' => {
                                                         'variables' => {
                                                                          'ip' => '- host:$h if:$card ip',
                                                                          'card' => '- if',
                                                                          'h' => '- host'
                                                                        },
                                                         'formula' => '$ip'
                                                       },
                                          'type' => 'leaf',
                                          'value_type' => 'string'
                                        }
                                      ]
                       },
                       'MasterModel::Slave',
                       {
                         'element' => [
                                        'X',
                                        {
                                          'type' => 'leaf',
                                          'value_type' => 'enum',
                                          'choice' => [
                                                        'Av',
                                                        'Bv',
                                                        'Cv'
                                                      ],
                                          'warp' => {
                                                      'rules' => [
                                                                   '$f1 eq \'B\'',
                                                                   {
                                                                     'default' => 'Bv'
                                                                   },
                                                                   '$f1 eq \'A\'',
                                                                   {
                                                                     'default' => 'Av'
                                                                   }
                                                                 ],
                                                      'follow' => {
                                                                    'f1' => '- - macro'
                                                                  }
                                                    }
                                        },
                                        'Y',
                                        {
                                          'value_type' => 'enum',
                                          'type' => 'leaf',
                                          'warp' => {
                                                      'follow' => {
                                                                    'f1' => '- - macro'
                                                                  },
                                                      'rules' => [
                                                                   '$f1 eq \'B\'',
                                                                   {
                                                                     'default' => 'Bv'
                                                                   },
                                                                   '$f1 eq \'A\'',
                                                                   {
                                                                     'default' => 'Av'
                                                                   }
                                                                 ]
                                                    },
                                          'choice' => [
                                                        'Av',
                                                        'Bv',
                                                        'Cv'
                                                      ]
                                        },
                                        'Z',
                                        {
                                          'warp' => {
                                                      'rules' => [
                                                                   '$f1 eq \'B\'',
                                                                   {
                                                                     'default' => 'Bv'
                                                                   },
                                                                   '$f1 eq \'A\'',
                                                                   {
                                                                     'default' => 'Av'
                                                                   }
                                                                 ],
                                                      'follow' => {
                                                                    'f1' => '- - macro'
                                                                  }
                                                    },
                                          'choice' => [
                                                        'Av',
                                                        'Bv',
                                                        'Cv'
                                                      ],
                                          'type' => 'leaf',
                                          'value_type' => 'enum'
                                        },
                                        'recursive_slave',
                                        {
                                          'cargo' => {
                                                       'config_class_name' => 'MasterModel::RSlave',
                                                       'type' => 'node'
                                                     },
                                          'index_type' => 'string',
                                          'type' => 'hash'
                                        },
                                        'W',
                                        {
                                          'type' => 'leaf',
                                          'value_type' => 'enum',
                                          'warp' => {
                                                      'rules' => [
                                                                   '$f1 eq \'B\'',
                                                                   {
                                                                     'level' => 'normal',
                                                                     'choice' => [
                                                                                   'Av',
                                                                                   'Bv',
                                                                                   'Cv'
                                                                                 ],
                                                                     'default' => 'Bv'
                                                                   },
                                                                   '$f1 eq \'A\'',
                                                                   {
                                                                     'choice' => [
                                                                                   'Av',
                                                                                   'Bv',
                                                                                   'Cv'
                                                                                 ],
                                                                     'level' => 'normal',
                                                                     'default' => 'Av'
                                                                   }
                                                                 ],
                                                      'follow' => {
                                                                    'f1' => '- - macro'
                                                                  }
                                                    },
                                          'level' => 'hidden'
                                        },
                                        'Comp',
                                        {
                                          'type' => 'leaf',
                                          'value_type' => 'string',
                                          'compute' => {
                                                         'formula' => 'macro is $m',
                                                         'variables' => {
                                                                          'm' => '- - macro'
                                                                        }
                                                       }
                                        }
                                      ]
                       },
                       'MasterModel::SlaveY',
                       {
                         'element' => [
                                        'std_id',
                                        {
                                          'index_type' => 'string',
                                          'cargo' => {
                                                       'config_class_name' => 'MasterModel::SlaveZ',
                                                       'type' => 'node'
                                                     },
                                          'type' => 'hash'
                                        },
                                        'sub_slave',
                                        {
                                          'type' => 'node',
                                          'config_class_name' => 'MasterModel::SubSlave'
                                        },
                                        'warp2',
                                        {
                                          'config_class_name' => 'MasterModel::SubSlave',
                                          'warp' => {
                                                      'rules' => [
                                                                   '$f1 eq \'mXY\'',
                                                                   {
                                                                     'config_class_name' => 'MasterModel::SubSlave2'
                                                                   },
                                                                   '$f1 eq \'XZ\'',
                                                                   {
                                                                     'config_class_name' => 'MasterModel::SubSlave2'
                                                                   }
                                                                 ],
                                                      'follow' => {
                                                                    'f1' => '! tree_macro'
                                                                  }
                                                    },
                                          'morph' => '1',
                                          'type' => 'warped_node'
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
                                      ]
                       },
                       'MasterModel::SlaveZ',
                       {
                         'include' => [
                                        'MasterModel::X_base_class'
                                      ],
                         'element' => [
                                        'Z',
                                        {
                                          'choice' => [
                                                        'Av',
                                                        'Bv',
                                                        'Cv'
                                                      ],
                                          'value_type' => 'enum',
                                          'type' => 'leaf'
                                        },
                                        'DX',
                                        {
                                          'value_type' => 'enum',
                                          'default' => 'Dv',
                                          'type' => 'leaf',
                                          'choice' => [
                                                        'Av',
                                                        'Bv',
                                                        'Cv',
                                                        'Dv'
                                                      ]
                                        }
                                      ]
                       },
                       'MasterModel::SubSlave',
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
                                          'value_type' => 'string',
                                          'type' => 'leaf'
                                        },
                                        'ad',
                                        {
                                          'value_type' => 'string',
                                          'type' => 'leaf'
                                        },
                                        'sub_slave',
                                        {
                                          'config_class_name' => 'MasterModel::SubSlave2',
                                          'type' => 'node'
                                        }
                                      ]
                       },
                       'MasterModel::SubSlave2',
                       {
                         'element' => [
                                        'aa2',
                                        {
                                          'value_type' => 'string',
                                          'type' => 'leaf'
                                        },
                                        'ab2',
                                        {
                                          'value_type' => 'string',
                                          'type' => 'leaf'
                                        },
                                        'ac2',
                                        {
                                          'value_type' => 'string',
                                          'type' => 'leaf'
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
                                      ]
                       },
                       'MasterModel::TolerantNode',
                       {
                         'accept' => [
                                       'list.*',
                                       {
                                         'type' => 'list',
                                         'cargo' => {
                                                      'value_type' => 'string',
                                                      'type' => 'leaf'
                                                    }
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
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        }
                                      ]
                       },
                       'MasterModel::WarpedId',
                       {
                         'element' => [
                                        'macro',
                                        {
                                          'choice' => [
                                                        'A',
                                                        'B',
                                                        'C'
                                                      ],
                                          'value_type' => 'enum',
                                          'type' => 'leaf'
                                        },
                                        'version',
                                        {
                                          'type' => 'leaf',
                                          'default' => '1',
                                          'value_type' => 'integer'
                                        },
                                        'warped_hash',
                                        {
                                          'max_nb' => '3',
                                          'cargo' => {
                                                       'type' => 'node',
                                                       'config_class_name' => 'MasterModel::WarpedIdSlave'
                                                     },
                                          'index_type' => 'integer',
                                          'warp' => {
                                                      'follow' => {
                                                                    'f1' => '- macro'
                                                                  },
                                                      'rules' => [
                                                                   '$f1 eq \'B\'',
                                                                   {
                                                                     'max_nb' => '2'
                                                                   },
                                                                   '$f1 eq \'A\'',
                                                                   {
                                                                     'max_nb' => '1'
                                                                   }
                                                                 ]
                                                    },
                                          'type' => 'hash'
                                        },
                                        'multi_warp',
                                        {
                                          'warp' => {
                                                      'follow' => {
                                                                    'f1' => '- macro',
                                                                    'f0' => '- version'
                                                                  },
                                                      'rules' => [
                                                                   '$f0 eq \'2\' and $f1 eq \'C\'',
                                                                   {
                                                                     'default_keys' => [
                                                                                         '0',
                                                                                         '1',
                                                                                         '2',
                                                                                         '3',
                                                                                         '4',
                                                                                         '5',
                                                                                         '6',
                                                                                         '7'
                                                                                       ],
                                                                     'max_index' => '7'
                                                                   },
                                                                   '$f0 eq \'2\' and $f1 eq \'A\'',
                                                                   {
                                                                     'default_keys' => [
                                                                                         '0',
                                                                                         '1',
                                                                                         '2',
                                                                                         '3',
                                                                                         '4',
                                                                                         '5',
                                                                                         '6',
                                                                                         '7'
                                                                                       ],
                                                                     'max_index' => '7'
                                                                   }
                                                                 ]
                                                    },
                                          'type' => 'hash',
                                          'default_keys' => [
                                                              '0',
                                                              '1',
                                                              '2',
                                                              '3'
                                                            ],
                                          'max_index' => '3',
                                          'min_index' => '0',
                                          'cargo' => {
                                                       'config_class_name' => 'MasterModel::WarpedIdSlave',
                                                       'type' => 'node'
                                                     },
                                          'index_type' => 'integer'
                                        },
                                        'hash_with_warped_value',
                                        {
                                          'type' => 'hash',
                                          'index_type' => 'string',
                                          'cargo' => {
                                                       'type' => 'leaf',
                                                       'value_type' => 'string',
                                                       'warp' => {
                                                                   'follow' => {
                                                                                 'f1' => '- macro'
                                                                               },
                                                                   'rules' => [
                                                                                '$f1 eq \'A\'',
                                                                                {
                                                                                  'default' => 'dumb string'
                                                                                }
                                                                              ]
                                                                 }
                                                     },
                                          'level' => 'hidden',
                                          'warp' => {
                                                      'follow' => {
                                                                    'f1' => '- macro'
                                                                  },
                                                      'rules' => [
                                                                   '$f1 eq \'A\'',
                                                                   {
                                                                     'level' => 'normal'
                                                                   }
                                                                 ]
                                                    }
                                        },
                                        'multi_auto_create',
                                        {
                                          'warp' => {
                                                      'follow' => {
                                                                    'f1' => '- macro',
                                                                    'f0' => '- version'
                                                                  },
                                                      'rules' => [
                                                                   '$f0 eq \'2\' and $f1 eq \'C\'',
                                                                   {
                                                                     'max_index' => '7',
                                                                     'auto_create_keys' => [
                                                                                             '0',
                                                                                             '1',
                                                                                             '2',
                                                                                             '3',
                                                                                             '4',
                                                                                             '5',
                                                                                             '6',
                                                                                             '7'
                                                                                           ]
                                                                   },
                                                                   '$f0 eq \'2\' and $f1 eq \'A\'',
                                                                   {
                                                                     'max_index' => '7',
                                                                     'auto_create_keys' => [
                                                                                             '0',
                                                                                             '1',
                                                                                             '2',
                                                                                             '3',
                                                                                             '4',
                                                                                             '5',
                                                                                             '6',
                                                                                             '7'
                                                                                           ]
                                                                   }
                                                                 ]
                                                    },
                                          'auto_create_keys' => [
                                                                  '0',
                                                                  '1',
                                                                  '2',
                                                                  '3'
                                                                ],
                                          'type' => 'hash',
                                          'cargo' => {
                                                       'config_class_name' => 'MasterModel::WarpedIdSlave',
                                                       'type' => 'node'
                                                     },
                                          'index_type' => 'integer',
                                          'max_index' => '3',
                                          'min_index' => '0'
                                        }
                                      ]
                       },
                       'MasterModel::WarpedIdSlave',
                       {
                         'element' => [
                                        'X',
                                        {
                                          'choice' => [
                                                        'Av',
                                                        'Bv',
                                                        'Cv'
                                                      ],
                                          'type' => 'leaf',
                                          'value_type' => 'enum'
                                        },
                                        'Y',
                                        {
                                          'value_type' => 'enum',
                                          'type' => 'leaf',
                                          'choice' => [
                                                        'Av',
                                                        'Bv',
                                                        'Cv'
                                                      ]
                                        },
                                        'Z',
                                        {
                                          'choice' => [
                                                        'Av',
                                                        'Bv',
                                                        'Cv'
                                                      ],
                                          'type' => 'leaf',
                                          'value_type' => 'enum'
                                        }
                                      ]
                       },
                       'MasterModel::WarpedValues',
                       {
                         'element' => [
                                        'get_element',
                                        {
                                          'value_type' => 'enum',
                                          'type' => 'leaf',
                                          'choice' => [
                                                        'm_value_element',
                                                        'compute_element'
                                                      ]
                                        },
                                        'where_is_element',
                                        {
                                          'type' => 'leaf',
                                          'value_type' => 'enum',
                                          'choice' => [
                                                        'get_element'
                                                      ]
                                        },
                                        'macro',
                                        {
                                          'choice' => [
                                                        'A',
                                                        'B',
                                                        'C',
                                                        'D'
                                                      ],
                                          'type' => 'leaf',
                                          'value_type' => 'enum'
                                        },
                                        'macro2',
                                        {
                                          'level' => 'hidden',
                                          'warp' => {
                                                      'rules' => [
                                                                   '$f1 eq \'B\'',
                                                                   {
                                                                     'level' => 'normal',
                                                                     'choice' => [
                                                                                   'A',
                                                                                   'B',
                                                                                   'C',
                                                                                   'D'
                                                                                 ]
                                                                   }
                                                                 ],
                                                      'follow' => {
                                                                    'f1' => '- macro'
                                                                  }
                                                    },
                                          'type' => 'leaf',
                                          'value_type' => 'enum'
                                        },
                                        'm_value',
                                        {
                                          'type' => 'leaf',
                                          'value_type' => 'enum',
                                          'warp' => {
                                                      'rules' => [
                                                                   '$m eq "A" or $m eq "D"',
                                                                   {
                                                                     'help' => {
                                                                                 'Av' => 'Av help'
                                                                               },
                                                                     'choice' => [
                                                                                   'Av',
                                                                                   'Bv'
                                                                                 ]
                                                                   },
                                                                   '$m eq "B"',
                                                                   {
                                                                     'help' => {
                                                                                 'Bv' => 'Bv help'
                                                                               },
                                                                     'choice' => [
                                                                                   'Bv',
                                                                                   'Cv'
                                                                                 ]
                                                                   },
                                                                   '$m eq "C"',
                                                                   {
                                                                     'choice' => [
                                                                                   'Cv'
                                                                                 ],
                                                                     'help' => {
                                                                                 'Cv' => 'Cv help'
                                                                               }
                                                                   }
                                                                 ],
                                                      'follow' => {
                                                                    'm' => '- macro'
                                                                  }
                                                    }
                                        },
                                        'm_value_old',
                                        {
                                          'warp' => {
                                                      'rules' => [
                                                                   '$f1 eq \'A\' or $f1 eq \'D\'',
                                                                   {
                                                                     'help' => {
                                                                                 'Av' => 'Av help'
                                                                               },
                                                                     'choice' => [
                                                                                   'Av',
                                                                                   'Bv'
                                                                                 ]
                                                                   },
                                                                   '$f1 eq \'B\'',
                                                                   {
                                                                     'help' => {
                                                                                 'Bv' => 'Bv help'
                                                                               },
                                                                     'choice' => [
                                                                                   'Bv',
                                                                                   'Cv'
                                                                                 ]
                                                                   },
                                                                   '$f1 eq \'C\'',
                                                                   {
                                                                     'choice' => [
                                                                                   'Cv'
                                                                                 ],
                                                                     'help' => {
                                                                                 'Cv' => 'Cv help'
                                                                               }
                                                                   }
                                                                 ],
                                                      'follow' => {
                                                                    'f1' => '- macro'
                                                                  }
                                                    },
                                          'type' => 'leaf',
                                          'value_type' => 'enum'
                                        },
                                        'compute',
                                        {
                                          'compute' => {
                                                         'formula' => 'macro is $m, my element is &element',
                                                         'variables' => {
                                                                          'm' => '-  macro'
                                                                        }
                                                       },
                                          'type' => 'leaf',
                                          'value_type' => 'string'
                                        },
                                        'var_path',
                                        {
                                          'mandatory' => '1',
                                          'compute' => {
                                                         'replace' => {
                                                                        'compute_element' => 'compute',
                                                                        'm_value_element' => 'm_value'
                                                                      },
                                                         'variables' => {
                                                                          'where' => '- where_is_element',
                                                                          'v' => '- $replace{$s}',
                                                                          's' => '- $where'
                                                                        },
                                                         'formula' => 'get_element is $replace{$s}, indirect value is \'$v\''
                                                       },
                                          'value_type' => 'string',
                                          'type' => 'leaf'
                                        },
                                        'class',
                                        {
                                          'index_type' => 'string',
                                          'cargo' => {
                                                       'type' => 'leaf',
                                                       'value_type' => 'string'
                                                     },
                                          'type' => 'hash'
                                        },
                                        'warped_out_ref',
                                        {
                                          'level' => 'hidden',
                                          'warp' => {
                                                      'rules' => [
                                                                   '$m eq "A" or $m2 eq "A"',
                                                                   {
                                                                     'level' => 'normal'
                                                                   }
                                                                 ],
                                                      'follow' => {
                                                                    'm2' => '- macro2',
                                                                    'm' => '- macro'
                                                                  }
                                                    },
                                          'refer_to' => '- class',
                                          'type' => 'leaf',
                                          'value_type' => 'reference'
                                        },
                                        'bar',
                                        {
                                          'type' => 'node',
                                          'config_class_name' => 'MasterModel::Slave'
                                        },
                                        'foo',
                                        {
                                          'type' => 'node',
                                          'config_class_name' => 'MasterModel::Slave'
                                        },
                                        'foo2',
                                        {
                                          'type' => 'node',
                                          'config_class_name' => 'MasterModel::Slave'
                                        }
                                      ]
                       },
                       'MasterModel::X_base_class',
                       {
                         'include' => [
                                        'MasterModel::X_base_class2'
                                      ]
                       },
                       'MasterModel::X_base_class2',
                       {
                         'class_description' => 'rather dummy class to check include',
                         'element' => [
                                        'X',
                                        {
                                          'choice' => [
                                                        'Av',
                                                        'Bv',
                                                        'Cv'
                                                      ],
                                          'type' => 'leaf',
                                          'value_type' => 'enum'
                                        }
                                      ]
                       },
                       'Master::Created',
                       {
                         'element' => [
                                        'created1',
                                        {
                                          'type' => 'leaf',
                                          'value_type' => 'number'
                                        },
                                        'created2',
                                        {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        }
                                      ]
                       }
                     ],
          'application' => {
                             'goner' => {
                                          'model' => 'MasterModel',
                                          'allow_config_file_override' => '1',
                                          'category' => 'application'
                                        },
                             'master' => {
                                           'allow_config_file_override' => '1',
                                           'model' => 'MasterModel',
                                           'category' => 'application'
                                         }
                           }
        };
