#
# This file is part of Config-Model-Approx
#
# This software is Copyright (c) 2015-2018 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

$model_to_test = "Approx" ;
$conf_file_name = 'approx.conf';
$conf_dir = '/etc/approx' ;

@tests = (
    {
        name => 'basic' ,
        check => {
            # 'AuthorizedKeysFile:0' => '/etc/ssh/userkeys/%u',
            # 'AuthorizedKeysFile:1' => '/var/lib/misc/userkeys2/%u',
        },
        file_contents_like => {
            # '/etc/ssh/sshd_config' => qr!/etc/ssh/userkeys/%u /var/lib/misc/userkeys2/%u! ,
        }
    },
);

1;
