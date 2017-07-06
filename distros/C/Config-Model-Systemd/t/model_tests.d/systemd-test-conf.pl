#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2015-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# systemd tests (system files)

# can be removed once Config::model::tester 3.002 is out
$model_to_test = "Systemd";

$conf_dir = '/etc/systemd/system/';

# list of tests. This modules looks for @tests global variable
@tests = (
    {
        name => 'sshd-service',
        backend_arg => 'sshd',
        setup => {
            'main-sshd' => $conf_dir.'sshd.service.d/override.conf',
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
        },
        load => "service:sshd Unit Description~",
        # file is removed because the load instruction above removes the only setting in there
        file_check_sub => sub {
            my $list_ref = shift ;
            @$list_ref = grep { $_ ne '/etc/systemd/system/sshd.service'} @$list_ref;
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

1; # to keep Perl happy
