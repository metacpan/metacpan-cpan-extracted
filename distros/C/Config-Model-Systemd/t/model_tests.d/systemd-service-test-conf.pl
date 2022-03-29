#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2008-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# systemd tests (system files)

use strict;
use warnings;

my $conf_dir = '/etc/systemd/system/';

# list of tests.
my @tests = (
    {
        name => 'sshd-service',
        config_file => $conf_dir.'sshd.service',
        data_from_group => 'systemd',
        setup => {
            'main-sshd' => $conf_dir.'sshd.service.d/override.conf',
            # create symlink from array elements to target file (the last of the array)
            'ssh.service' => [ $conf_dir.'/sshd.service', '/lib/systemd/system/ssh.service' ]
        },
        check => {
            'Service ExecStartPre:0' => { mode => 'layered', value => '/usr/sbin/sshd -t'},
            'Service ExecReload:0' => { mode => 'layered', value => '/usr/sbin/sshd -t'},
            'Service ExecReload:1' => { mode => 'layered', value => '/bin/kill -HUP $MAINPID'},
            'Unit Description' => "OpenBSD Secure Shell server - test override",
        },
        wr_check => {
            'Unit Description' =>  { mode => 'custom', value => "OpenBSD Secure Shell server - test override"},
        }
    },

    {
        name => 'transmission',
        config_file => $conf_dir.'transmission-daemon.service',
        data_from_group => 'systemd',
        setup => {
            'transmission-daemon.service' => '/lib/systemd/system/transmission-daemon.service'
        },
        load => 'Unit After:<you',
        check => {
            'Unit After:0' => { mode => 'user', value => "network.target"},
            'Unit After:1' => "you",
        },
        file_check_sub => sub {
            my $list_ref = shift ;
            push @$list_ref , '/etc/systemd/system/transmission-daemon.service.d/override.conf';
        },
    },

    {
        name => 'condition-list',
        config_file => $conf_dir.'main-test.service',
        data_from_group => 'systemd',
        setup => {
            # Debian  #850228
            'main-test' => $conf_dir.'main-test.service.d/override.conf',
        }
    },

);

return {
    tests => \@tests,
    conf_dir => $conf_dir,
}
