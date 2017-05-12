#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

[
    [
        name => "Itself::CargoElement",

        include =>
          [ 'Itself::NonWarpableElement', 'Itself::WarpableCargoElement' ],
        include_after => 'type',

        'element' => [

            # structural information
            'type' => {
                type        => 'leaf',
                value_type  => 'enum',
                choice      => [qw/node warped_node leaf check_list/],
                mandatory   => 1,
                description => 'specify the type of the cargo.',
            },

            # node element (may be within a hash or list)

            'warp' => {
                type   => 'warped_node',              # ?
                level  => 'hidden',

                warp => {
                    follow => { elt_type => '- type' },
                    rules => [
                        '$elt_type ne "node"' => {
                            level             => 'normal',
                            config_class_name => 'Itself::WarpValue',
                        }
                    ],
                },
                description =>
                    "change the properties (i.e. default value or its value_type) "
                  . "dynamically according to the value of another Value object locate "
                  . "elsewhere in the configuration tree. "

            },

        ],

    ],

];
