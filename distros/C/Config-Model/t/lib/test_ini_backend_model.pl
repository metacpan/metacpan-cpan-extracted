#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# test model used by t/*.t
use strict;
use warnings;


return [
    {
        rw_config => {
            backend     => 'IniFile',
            config_dir  => '/etc/',
            file        => 'test.ini',
            auto_create => 1,
            auto_delete => 1,
        },

        name => 'IniTest',

        element => [
            [qw/foo bar/] => {
                type  => 'list',
                cargo => {
                    type       => 'leaf',
                    value_type => 'uniline',
                }
            },

            [qw/baz/] => {
                qw/type leaf value_type uniline/,
            },
            [qw/class1 class2/] => {
                type              => 'node',
                config_class_name => 'IniTest::Class'
            }
        ]
    },
    {
        rw_config => {
            backend           => 'IniFile',
            config_dir        => '/etc/',
            file              => 'test.ini',
            auto_create       => 1,
            comment_delimiter => ';',
        },

        name => 'IniTest2',

        element => [
            [qw/foo bar/] => {
                type  => 'list',
                cargo => {
                    type       => 'leaf',
                    value_type => 'uniline',
                }
            },

            [qw/baz/] => {
                qw/type leaf value_type uniline/,
            },
            [qw/class1 class2/] => {
                type              => 'node',
                config_class_name => 'IniTest::Class'
            }
        ]
    },
    {
        name => 'IniTest3',

        rw_config => {
            backend           => 'IniFile',
            config_dir        => '/etc/',
            file              => 'test.ini',
            auto_create       => 1,
            comment_delimiter => '#;',
        },

        element => [
            [qw/foo bar/] => {
                type  => 'list',
                cargo => {
                    type       => 'leaf',
                    value_type => 'uniline',
                }
            },

            [qw/baz/] => {
                qw/type leaf value_type uniline/,
            },
            [qw/class1 class2/] => {
                type              => 'node',
                config_class_name => 'IniTest::Class'
            }
        ]
    },
    {
        name    => 'IniTest::Class',
        element => [
            [qw/lista listb/] => {
                type  => 'list',
                cargo => {
                    type       => 'leaf',
                    value_type => 'uniline',
                },
            },
        ]
    },
    {
        name        => 'AutoIni',
        rw_config => {
            backend     => 'IniFile',
            config_dir  => '/etc/',
            file        => 'test.ini',
            auto_create => 1,
        },
        accept => [
            'class.*' => {
                'type'              => 'node',
                'config_class_name' => 'AutoIniClass'
            },
            '.*' => {
                'type' => 'list',
                cargo  => {qw/type leaf value_type uniline/},
            }
        ],
    },
    {
        name   => 'AutoIniClass',
        accept => [
            '.*' => {
                'type' => 'list',
                cargo  => {qw/type leaf value_type uniline/},
            }
        ],
    },
    {
        name => "MyClass",

        element => [
            [qw/foo bar/] => {
                'type' => 'list',
                cargo  => {qw/type leaf value_type uniline/},
            },
            [qw/baz/] => {
                qw/type leaf value_type uniline/,
            },
            'any_ini_class' => {
                type       => 'hash',
                index_type => 'string',
                cargo      => {
                    type              => 'node',
                    config_class_name => 'AutoIniClass'
                },
            },
        ],

        rw_config => {
            backend     => 'IniFile',
            config_dir        => '/etc/',
            file              => 'test.ini',
            store_class_in_hash => 'any_ini_class',
            auto_create => 1,
        },
    },
    {
        name => 'IniCheck',
        rw_config => {
            backend           => 'IniFile',
            file              => 'test.ini',
            auto_create       => 1,
        },

        element => [
            [qw/foo bar/] => {
                type  => 'check_list',
                choice => [qw/foo1 foo2 bar1/],
            },

            [qw/baz/] => {
                qw/type leaf value_type uniline/,
            },
            [qw/class1 class2/] => {
                type              => 'node',
                config_class_name => 'IniCheckList::Class'
            }
        ]
    },
    {
        name    => 'IniCheckList::Class',
        element => [
            [qw/lista/] => {
                type  => 'check_list',
                choice => [qw/lista1 lista2 lista3 nolist/],
            },
        ]
    },
    {
        name => 'IniDQuotes',
        rw_config => {
            backend           => 'IniFile',
            file              => 'test.ini',
            auto_create       => 1,
            quote_value       => 'shell_style',
        },

        element => [
            baz => {
                qw/type leaf value_type string/,
            },
            a_list => {
                type  => 'list',
                cargo => {
                    type       => 'leaf',
                    value_type => 'uniline',
                }
            },

        ]
    },
];
