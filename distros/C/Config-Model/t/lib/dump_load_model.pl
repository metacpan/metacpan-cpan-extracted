# -*- cperl -*-
#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

# this file is used by test script

return [
    [
        name    => 'SubSlave2',
        element => [
            [qw/aa2 ab2 ac2 ad2 Z/] => { type => 'leaf', value_type => 'string' } ]
    ],

    [
        name    => 'SubSlave',
        element => [
            [qw/aa ab ac ad/] => { type => 'leaf', value_type => 'string' },
            sub_slave         => {
                type              => 'node',
                config_class_name => 'SubSlave2',
            } ]
    ],

    [
        name    => 'X_base_class2',
        element => [
            X => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/Av Bv Cv/]
            },
        ],
        class_description => 'rather dummy class to check include feature',
    ],

    [
        name    => 'X_base_class',
        include => 'X_base_class2',
    ],

    [
        name    => 'SlaveZ',
        element => [
            [ 'Z', 'X-Y-Z' ] => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/Av Bv Cv/]
            },
            [qw/DX/] => {
                type       => 'leaf',
                value_type => 'enum',
                default    => 'Dv',
                choice     => [qw/Av Bv Cv Dv/]
            },
        ],
        include       => 'X_base_class',
        include_after => 'Z',
    ],

    [
        name    => 'SlaveY',
        element => [
            std_id => {
                type              => 'hash',
                index_type        => 'string',
                cargo => {
                    type        => 'node',
                    config_class_name => 'SlaveZ'
                },
            },
            sub_slave => {
                type              => 'node',
                config_class_name => 'SubSlave',
            },
            warp2 => {
                type              => 'warped_node',
                config_class_name => 'SubSlave',
                morph             => 1,
                warp => {
                    follow            => '! tree_macro',
                    rules             => [
                        mXY => { config_class_name => 'SubSlave2' },
                        XZ  => { config_class_name => 'SubSlave2' }
                    ]
                }
            },
            Y => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/Av Bv Cv/]
            },
        ],
        include => 'X_base_class',
    ],

    [
        name              => 'Master',
        class_description => "Master description",
        level             => [ [qw/lista hash_a tree_macro int_v/] => 'important' ],
        element           => [
            std_id => {
                type              => 'hash',
                index_type        => 'string',
                cargo => {
                    type        => 'node',
                    config_class_name => 'SlaveZ',
                },
            },
            [qw/lista listb listc/] => {
                type       => 'list',
                cargo => {
                    type => 'leaf',
                    value_type => 'string'
                },
            },
            [qw/hash_a hash_b/] => {
                type       => 'hash',
                index_type => 'string',
                cargo => {
                    type => 'leaf',
                    value_type => 'string'
                },
                summary    => "hash_* summary",
            },
            ordered_hash => {
                type       => 'hash',
                index_type => 'string',
                ordered    => 1,
                cargo => {
                    type => 'leaf',
                    value_type => 'string'
                },
            },
            ordered_hash_of_node => {
                type       => 'hash',
                index_type => 'string',
                ordered    => 1,
                cargo => {
                    type => 'node',
                    config_class_name => 'SubSlave2',
                }
            },
            olist => {
                type              => 'list',
                cargo => {
                    type        => 'node',
                    config_class_name => 'SlaveZ'
                },
            },
            bool_list => {
                type => 'list',
                cargo => {
                    type => 'leaf',
                    value_type => 'boolean'
                }
            },
            int_list_with_max => {
                type => 'list',
                cargo => {
                    type => 'leaf',
                    value_type => 'integer',
                    max => 10,
                }
            },
            tree_macro => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/XY XZ mXY/],
                help       => {
                    XY  => 'XY help',
                    XZ  => 'XZ help',
                    mXY => 'mXY help',
                }
            },
            warp => {
                type              => 'warped_node',
                config_class_name => 'SlaveY',
                morph             => 1,
                warp => {
                    follow            => '! tree_macro',
                    rules             => [
                        #XY => { config_class_name => 'SlaveY'},
                        mXY => { config_class_name => 'SlaveY' },
                        XZ  => { config_class_name => 'SlaveZ' }
                    ]
                }
            },

            'slave_y' => {
                type              => 'node',
                config_class_name => 'SlaveY',
            },

            string_with_def => {
                type       => 'leaf',
                value_type => 'string',
                default    => 'yada yada'
            },
            a_uniline => {
                type       => 'leaf',
                value_type => 'uniline',
                default    => 'yada yada'
            },
            a_string => {
                type       => 'leaf',
                value_type => 'string'
            },
            a_string2 => {
                type       => 'leaf',
                value_type => 'string'
            },
            a_string_to_test_newline => {
                type       => 'leaf',
                value_type => 'string'
            },
            another_string => {
                type       => 'leaf',
                mandatory  => 1,
                value_type => 'string'
            },
            hidden_string => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'string',
                warp       => {
                    follow => '! tree_macro',
                    rules  => {
                        XZ => {
                            level => 'normal',
                        } }
                },
            },
            int_v => {
                type       => 'leaf',
                value_type => 'integer',
                default    => '10',
                min        => 5,
                max        => 15
            },
            alpha_check_list => {
                type => 'check_list',
                choice     => ['A' .. 'Z'],
            },
            my_check_list => {
                type     => 'check_list',
                refer_to => '- hash_a + ! hash_b',
            },
            my_reference => {
                type       => 'leaf',
                value_type => 'reference',
                refer_to   => '- hash_a + ! hash_b',
            },
            plain_object => {
                type              => 'node',
                config_class_name => 'SubSlave2',
            }
        ],
        description => [
            tree_macro => 'controls behavior of other elements'
        ]
    ],
];

# do not put 1; at the end or Model-> load will not work
