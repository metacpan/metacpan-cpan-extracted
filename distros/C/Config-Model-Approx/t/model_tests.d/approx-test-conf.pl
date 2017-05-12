#
# This file is part of Config-Model-Approx
#
# This software is Copyright (c) 2013 by Dominique Dumont.
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
        load_warnings => undef , # some weird warnings pop up in Perl smoke tests with perl 5.15.9
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
