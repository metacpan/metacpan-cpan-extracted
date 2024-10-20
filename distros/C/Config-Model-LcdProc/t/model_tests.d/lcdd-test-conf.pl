#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2023 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

my @fix_warnings ;

push @fix_warnings,
    (
        #load_warnings => [ qr/code check returned false/ ],
        load => "server DriverPath=/tmp/" , # just a work-around
    )
    unless -d '/usr/lib/lcdproc/' ;

my @tests = (
    {
        # t0
        check => {
            'server Hello:0',           qq!  Bienvenue! ,
            'server Hello:1',           qq(   LCDproc et Config::Model!) ,
            'server Driver', 'curses',
            'curses Size', '20x2',
            'server AutoRotate', 'off',
        },
        @fix_warnings ,
        errors => [
            # qr/value 2 > max limit 0/ => 'fs:"/var/chroot/lenny-i386/dev" fs_passno=0' ,
        ],
        file_contents_like => {
            "/etc/LCDd.conf" => qr!"  Bienvenue"!
        }
    },
    {
        # test upgrade from raw lcdproc 0.5.5
        name => 'LDCd-0.5.5',
        load_check => 'skip'
    },
    {
        # likewise for lcdproc 0.5.6
        name => 'LDCd-0.5.6',
        load_check => 'skip'
    },
    {
        name => 'with-2-drivers',
        check => {
            'server Hello:0',           qq!  Bienvenue! ,
            'server Hello:1',           qq(   LCDproc et Config::Model!) ,
            'server Driver', 'curses,lirc',
            'curses Size', '20x2',
            'server AutoRotate', 'off',
            'lirc prog','lcdd',
        },
        @fix_warnings ,
    },
);

return {
    model_to_test => "LCDd" ,
    conf_file_name => "LCDd.conf" ,
    conf_dir => "etc" ,
    tests => \@tests
};


