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

# test inifile backend with multiple ini files

# create minimal model to test ini file backend.

# this class is used by MultiMiniIni class below
my @config_classes = ({
    name    => 'MultiIniTest::Class',
    element => [
        int_with_max => {qw/type leaf value_type integer max 10/},
    ],
    rw_config => {
        backend     => 'IniFile',
        config_dir  => '/etc/',
        file        => '&index.conf',
        auto_create => 1,
    },
});

push @config_classes, {
    name => 'MultiMiniIni',
    element => [
        service => {
            type  => 'hash',
            index_type => 'string',
            # require to trigger load of bar.conf
            default_keys => 'bar',
            cargo => {
                type       => 'node',
                config_class_name => 'MultiIniTest::Class'
            }
        },
    ],
    rw_config => {
        backend     => 'perl',
        config_dir  => '/etc/',
        file        => 'service.pl',
        auto_create => 1,
    },
};


# the test suite
my @tests = (
    {
        name  => 'max-overflow',
        load_check => 'no',
        # work only with Config::Model > 2.094 because of an obscure
        # initialisation bug occuring while loading a bad value in
        # a sub-node (thanks systemd)
        load => 'service:bar int_with_max=9',
        file_check_sub => sub {
            my $list_ref = shift ;
            # file added because of default bar key
            push @$list_ref, "/etc/service.pl" ;
        },
    },
);

return {
    # specify the name of the class to test
    model_to_test => "MultiMiniIni",
    config_classes => \@config_classes,
    tests => \@tests
};
