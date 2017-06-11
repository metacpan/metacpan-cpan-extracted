#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
#    Copyright (c) 2007-2011 Dominique Dumont.
#
#    This file is part of Config-Model-Itself.
#
#    Config-Model-Itself is free software; you can redistribute it
#    and/or modify it under the terms of the GNU Lesser Public License
#    as published by the Free Software Foundation; either version 2.1
#    of the License, or (at your option) any later version.
#
#    Config-Model-Itself is distributed in the hope that it will be
#    useful, but WITHOUT ANY WARRANTY; without even the implied
#    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#    See the GNU Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model-Itself; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

[
    [
        name => 'Itself::NonWarpableElement',

        # warp often depend on this one, so list it first
        'element' => [
            'value_type' => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'enum',
                choice => [
                    qw/boolean enum integer reference
                       number uniline string file dir/
                ],
                'warp'     => {
                    follow  => { 't' => '- type' },
                    'rules' => [
                        '$t eq "leaf"' => {
                            level     => 'normal',
                            mandatory => 1,
                        }
                    ]
                },
                help => {
                    integer => 'positive or negative integer',
                    uniline => 'string with no embedded newline',
                }
            },

            'class' => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'uniline',
                summary    => "Override implementation of element",
                description =>
                "Perl class name used to override the implementation of the configuration element. "
                ."This override Perl class must inherit a Config::Model class that matches the element type, "
                ."i.e. Config::Model::Value, Config::Model::HashId or Config::Model::ListId. "
                ."Use with care.",
                'warp'     => {
                    follow  => { 't'              => '- type' },
                    'rules' => [ '$t and $t !~ /node/' => { level => 'normal', } ]
                }
            },

            'morph' => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'boolean',
                'warp'     => {
                    follow  => '- type',
                    'rules' => {
                        'warped_node' => {
                            level            => 'normal',
                            upstream_default => 0,
                        },
                    }
                },
                description =>
                  "When set, a recurse copy of the value from the old object "
                  . "to the new object is attemped. Old values are dropped when "
                  ." a copy is not possible (usually because of mismatching types) "
            },

            # end warp elements for warped_node

            # leaf element

            'refer_to' => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'uniline',
                warp       => {
                    follow => {
                        t  => '- type',
                        vt => '- value_type',
                    },
                    'rules' => [
                        '$t  eq "check_list" or $vt eq "reference"' =>
                          { level => 'important', },
                    ]
                },
                description =>
                  "points to an array or hash element in the configuration "
                  . "tree using the path syntax. The available choice of this "
                  . "reference value (or check list)is made from the available "
                  . "keys of the pointed hash element or the values of the pointed array element.",
            },

            'computed_refer_to' => {
                type   => 'warped_node',
                level      => 'hidden',
                warp => {
                    follow => {
                        t  => '- type',
                        vt => '- value_type',
                    },
                    'rules'    => [
                        '$t  eq "check_list" or $vt eq "reference"' => {
                            level             => 'normal',
                            config_class_name => 'Itself::ComputedValue',
                        },
                    ],
                },
                description =>
                  "points to an array or hash element in the configuration "
                  . "tree using a path computed with value from several other "
                  . "elements in the configuration tree. The available choice "
                  . "of this reference value (or check list) is made from the "
                  . "available keys of the pointed hash element or the values "
                  . "of the pointed array element. The keys of several hashes (or lists) "
                  . "can be combined by using the '+' operator in the formula. "
                  . "For instance, '! host:$a lan + ! host:foobar lan'. See "
                  . "L<Config::Model::IdElementReference> for more details."
            },

            'replace_follow' => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'uniline',
                warp       => {
                    follow  => { t               => '- type' },
                    'rules' => [ '$t  eq "leaf"' => { level => 'important', }, ]
                },
                description =>
                  "Path specifying a hash of value element in the configuration "
                  . "tree. The hash if used in a way similar to the replace "
                  . "parameter. In this case, the replacement is not coded "
                  . "in the model but specified by the configuration.",
            },

            'compute' => {
                type       => 'warped_node',
                level      => 'hidden',

                warp => {
                    follow  => { t => '- type', },
                    'rules' => [
                        '$t  eq "leaf"' => {
                            level             => 'normal',
                            config_class_name => 'Itself::ComputedValue',
                        },
                    ],
                },
                description =>
                  "compute the default value according to a formula and value "
                  . "from other elements in the configuration tree.",
            },

            'migrate_from' => {
                type       => 'warped_node',
                level      => 'hidden',

                warp => {
                    follow  => { t => '- type', },
                    'rules' => [
                        '$t  eq "leaf"' => {
                            level             => 'normal',
                            config_class_name => 'Itself::MigratedValue',
                        },
                    ],
                },
                description =>
                    "Specify an upgrade path from an old value and compute "
                  . "the value to store in the new element.",
            },

            'write_as' => {
                type       => 'list',
                level      => 'hidden',
                max_index  => 1,

                warp => {
                    follow  => { t => '- type', vt => '- value_type'},
                    rules   => [
                        '$t eq "leaf" and $vt eq "boolean"' => { level => 'normal', },
                    ]
                },
                cargo => {
                    type => 'leaf',
                    value_type => 'uniline',
                },
                description =>
                    "Specify how to write a boolean value. Example 'no' 'yes'.",
            },

            # hash or list element
            migrate_values_from => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'uniline',
                warp       => {
                    follow  => { 't'                            => '?type' },
                    'rules' => [ '$t eq "hash" or $t eq "list"' => { level => 'normal', } ]
                } ,
                description => 'Specifies that the values of the hash or list are copied '
                    . 'from another hash or list in the configuration tree once configuration '
                    . 'data are loaded.',
            },

            # hash element
            migrate_keys_from => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'uniline',
                warp       => {
                    follow  => { 't'            => '?type' },
                    'rules' => [ '$t eq "hash"' => { level => 'normal', } ]
                },
                description => 'Specifies that the keys of the hash are copied from another hash '
                    . 'in the configuration tree only when the hash is created.',
            },

            write_empty_value => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'boolean',
                upstream_default => 0,
                warp       => {
                    follow  => { 't'            => '?type' },
                    rules   => [ '$t eq "hash"' => { level => 'normal', } ]
                },
                description => 'By default, hash entries without data are not saved in configuration '
                    . 'files. Set this parameter to 1 if a key must be saved in the configuration '
                    . 'file even if the hash contains no value for that key.',
            },
            # list element

        ],
    ],
];
