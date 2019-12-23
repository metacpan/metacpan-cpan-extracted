#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2015-2018 by Dominique Dumont.
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
        backend_arg => 'sshd',
        setup => {
            'main-sshd' => $conf_dir.'sshd.service.d/override.conf',
            # create symlink from array elements to target file (the last of the array)
            # TODO: update C::M::Tester version require
            'ssh.service' => [ $conf_dir.'/sshd.service', '/lib/systemd/system/ssh.service' ]
        },
        check => {
            'service:sshd Service ExecStartPre:0' => { mode => 'layered', value => '/usr/sbin/sshd -t'},
            'service:sshd Service ExecReload:0' => { mode => 'layered', value => '/usr/sbin/sshd -t'},
            'service:sshd Service ExecReload:1' => { mode => 'layered', value => '/bin/kill -HUP $MAINPID'},
            'service:sshd Unit Description' => "OpenBSD Secure Shell server - test override",
        }
    },

    {
        name => 'disable-service',
        backend_arg => 'sshd',
        setup => {
            'main-sshd' => $conf_dir.'sshd.service.d/override.conf',
        },
        load => "service:sshd disable=1",
        wr_check => { 'service:sshd disable' => 1 },
        file_check_sub => sub {
            my $list_ref = shift ;
            unshift @$list_ref , '/etc/systemd/system/sshd.service';
        }
    },

    {
        name => 'remove-service',
        backend_arg => 'sshd',
        setup => {
            'main-sshd' => $conf_dir.'sshd.service.d/override.conf',
            'default-sshd' => '/lib/systemd/system/sshd.service',
            'mpd.service' => $conf_dir.'mpd.service.d/override.conf',
            'mpd.socket' => $conf_dir.'mpd.socket.d/override.conf',
            'default-alsa-state' => '/lib/systemd/system/alsa-state.service'
        },
        load => "service:sshd Unit Description~",
        # file is removed because the load instruction above removes the only setting in there
        file_check_sub => sub {
            my $list_ref = shift ;
            @$list_ref = grep { not m!/etc/.*/sshd.service!} @$list_ref;
        }
    },
    {
        name => 'condition-list',
        backend_arg => 'main-test',
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
