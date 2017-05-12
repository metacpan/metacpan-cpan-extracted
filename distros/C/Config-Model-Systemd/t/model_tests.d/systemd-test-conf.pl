#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2015-2016 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# systemd tests (system files)

$conf_dir = '/etc/systemd/system/';

# list of tests. This modules looks for @tests global variable
@tests = (
    {
        name => 'sshd-service',
        setup => {
            'main-sshd' => $conf_dir.'sshd.service',
        }
    },

    {
        name => 'disable-service',
        setup => {
            'main-sshd' => $conf_dir.'sshd.service',
        },
        load => "service:sshd disable=1",
        wr_check => { 'service:sshd disable' => 1 },
    },

    {
        name => 'remove-service',
        setup => {
            'main-sshd' => $conf_dir.'sshd.service',
            'default-sshd' => '/lib/systemd/system/sshd.service',
            'mpd.service' => $conf_dir.'mpd.service',
            'mpd.socket' => $conf_dir.'mpd.socket',
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
        setup => {
            # Debian  #850228
            'main-test' => $conf_dir.'main-test.service',
        }
    },

);

1; # to keep Perl happy
