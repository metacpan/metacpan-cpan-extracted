#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2008-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# systemd tests for user
use strict;
use warnings;

# list of tests.
my @tests = (
    {
        name => 'basic-socket',
        config_file => 'gmail-imap-tunnel.socket',
        check => [
            'Unit Description' => "Socket for Gmail IMAP tunnel",
            'Install WantedBy:0' => 'sockets.target',
            'Socket ListenStream:0' => 9995,
            'Socket Accept' => "yes"
        ],
        file_contents_unlike => {
            "gmail-imap-tunnel.socket" => qr/disable/ ,
        }
    },
);

return { tests => \@tests } ;
