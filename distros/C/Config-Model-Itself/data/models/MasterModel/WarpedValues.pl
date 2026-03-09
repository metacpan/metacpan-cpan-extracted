#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2026 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

return [
    [
        name    => "MasterModel::RSlave",
        element => [
            recursive_slave => {
                type              => 'hash',
                index_type        => 'string',
                cargo => {
                    type        => 'node',
                    config_class_name => 'MasterModel::RSlave',
                }
            },
            big_compute => {
                type       => 'hash',
                index_type => 'string',
                cargo => {
                    type => 'leaf',
                    value_type => 'string',
                    compute    => {
                        formula => 'macro is $m, my idx: &index, '
                          . 'my element &element, '
                          . 'upper element &element($up), '
                        . 'up idx &index($up)',
                        variables => {
                            'm' => '!  macro',
                            up  => '-'
                        }
                    }
                },
            },
            big_replace => {
                type       => 'leaf',
                value_type => 'string',
                compute    => {
                    formula => 'trad idx $replace{&index($up)}',
                    variables => {
                        up      => '-',
                    },
                    replace => {
                        l1 => 'level1',
                        l2 => 'level2'
                    }
                }
            },
            macro_replace => {
                type       => 'hash',
                index_type => 'string',
                cargo => {
                    type => 'leaf',
                    value_type => 'string',
                    compute    => {
                        formula => 'trad macro is $replace{$m}',
                        variables => {
                            'm'   => '!  macro',
                        },
                        replace => {
                            A => 'macroA',
                            B => 'macroB',
                            C => 'macroC'
                        }
                    }
                },
            }
        ],
    ],

    [
        name    => "MasterModel::Slave",
        element => [
            [qw/X Y Z/] => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/Av Bv Cv/],
                warp       => {
                    follow => '- - macro',
                    rules  => {
                        A => { default => 'Av' },
                        B => { default => 'Bv' }
                    }
                }
            },
            'recursive_slave' => {
                type              => 'hash',
                index_type        => 'string',
                cargo => {
                    type        => 'node',
                    config_class_name => 'MasterModel::RSlave',
                }
            },
            W => {
                type       => 'leaf',
                value_type => 'enum',
                level      => 'hidden',
                warp       => {
                    follow  => '- - macro',
                    'rules' => {
                        A => {
                            default    => 'Av',
                            level      => 'normal',
                            choice     => [qw/Av Bv Cv/],
                        },
                        B => {
                            default    => 'Bv',
                            level      => 'normal',
                            choice     => [qw/Av Bv Cv/]
                        }
                    }
                },
            },
            Comp => {
                type       => 'leaf',
                value_type => 'string',
                compute    => {
                    formula => 'macro is $m',
                    variables => {
                        'm' => '- - macro'
                    }
                },
            },
        ],
    ],
    [
        name    => "MasterModel::WarpedValues",
        element => [
            get_element => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/m_value_element compute_element/]
            },
            where_is_element => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/get_element/]
            },
            macro => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/A B C D/]
            },
            macro2 => {
                type       => 'leaf',
                value_type => 'enum',
                level      => 'hidden',
                warp       => {
                    follow  => '- macro',
                    'rules' => [
                        "B" => {
                            choice => [qw/A B C D/],
                            level  => 'normal'
                        },
                    ]
                }
            },
            'm_value' => {
                type       => 'leaf',
                value_type => 'enum',
                'warp'     => {
                    follow  => { m => '- macro' },
                    'rules' => [
                        '$m eq "A" or $m eq "D"' => {
                            choice => [qw/Av Bv/],
                            help   => { Av => 'Av help' },
                        },
                        '$m eq "B"' => {
                            choice => [qw/Bv Cv/],
                            help   => { Bv => 'Bv help' },
                        },
                        '$m eq "C"' => {
                            choice => [qw/Cv/],
                            help   => { Cv => 'Cv help' },
                        }
                    ]
                }
            },
            'm_value_old' => {
                type       => 'leaf',
                value_type => 'enum',
                'warp'     => {
                    follow  => '- macro',
                    'rules' => [
                        [qw/A D/] => {
                            choice => [qw/Av Bv/],
                            help   => { Av => 'Av help' },
                        },
                        B => {
                            choice => [qw/Bv Cv/],
                            help   => { Bv => 'Bv help' },
                        },
                        C => {
                            choice => [qw/Cv/],
                            help   => { Cv => 'Cv help' },
                        }
                    ]
                }
            },
            'compute' => {
                type       => 'leaf',
                value_type => 'string',
                compute => {
                    formula => 'macro is $m, my element is &element',
                    variables => {
                        'm' => '-  macro'
                    }
                }
            },

            'var_path' => {
                type       => 'leaf',
                value_type => 'string',
                mandatory  => 1,        # will croak if value cannot be computed
                compute    => {
                    formula => 'get_element is $replace{$s}, indirect value is \'$v\'',
                    variables => {
                        's'           => '- $where',
                        where         => '- where_is_element',
                        v             => '- $replace{$s}',
                    },
                    replace => {
                        qw/m_value_element m_value
                           compute_element compute/
                    }
                }
            },

            'class' => {
                type       => 'hash',
                index_type => 'string',
                cargo => {
                    type => 'leaf',
                    value_type => 'string'
                },
            },
            'warped_out_ref' => {
                type       => 'leaf',
                value_type => 'reference',
                refer_to   => '- class',
                level      => 'hidden',
                warp       => {
                    follow => { m => '- macro', m2 => '- macro2' },
                    rules =>
                      [ '$m eq "A" or $m2 eq "A"' => { level => 'normal', }, ]
                }
            },

            [qw/bar foo foo2/] => {
                type              => 'node',
                config_class_name => 'MasterModel::Slave'
            }
        ],
    ]
];
