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

# test inifile backend

# create minimal model to test ini file backend.

# this class is used by MiniIni class below
my @config_classes = ({
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
});

push @config_classes, {
    name => 'MiniIni',
        element => [
            [qw/foo bar/] => {
                type  => 'list',
                cargo => {
                    type       => 'leaf',
                    value_type => 'uniline',
                }
            },

            baz => {
                qw/type leaf value_type uniline/,
            },
            [qw/class1 class2/] => {
                type              => 'node',
                config_class_name => 'IniTest::Class'
            }
        ],
    rw_config => {
        backend     => 'IniFile',
        # specify where is the config file. this must match
        # the $conf_file_name and $conf_dir variable above
        config_dir  => '/etc/',
        file        => 'test.ini',
        file_mode   => 'a=r,ug+w',
        auto_create => 1,
    },
};


# the test suite
my @tests = (
    {   # test complex parameters
        name  => 'complex',
        check => [
            # check a specific value stored in example file
            baz => q!/bin/sh -c '[ "$(cat /etc/X11/default-display-manager 2>/dev/null)" = "/usr/bin/sddm" ]''!
        ],
        file_mode => {
            '/etc/test.ini' => oct(664)
        }
    },
);

return {
    # specify the name of the class to test
    model_to_test => "MiniIni",

    # specify where is the example file
    conf_file_name => 'test.ini',
    conf_dir => '/etc',

    config_classes => \@config_classes,
    tests => \@tests
};
