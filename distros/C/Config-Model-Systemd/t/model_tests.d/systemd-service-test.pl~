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
        name => 'transmission',
        backend_arg => 'transmission-daemon',
        setup => {
            'transmission-daemon.service' => '/lib/systemd/system/transmission-daemon.service'
        },
        load => 'service:transmission-daemon Unit After:<you',
        check => {
            'service:transmission-daemon Unit After:0' => { mode => 'user', value => "network.target"},
            'service:transmission-daemon Unit After:1' => "you",
        },
        file_check_sub => sub {
            my $list_ref = shift ;
            push @$list_ref , '/etc/systemd/system/transmission-daemon.service.d/override.conf';
        },
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

        # when loading sshd, no service or socker is found, so the backend create
        # and empty socket and empty service to cme edit shows both to users.
        # since they are not filled with data, no file is written
        # but dump tree test shows the difference, so we remove the empty socket.
        load2 => "socket:.rm(sshd)",

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
