#
# This file is part of Config-Model-OpenSsh
#
# This software is Copyright (c) 2014 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

$model_to_test = "Sshd" ;

my $map = {
   'darwin' => '/etc/sshd_config',
   'default' => '/etc/ssh/sshd_config',
} ;

my $target = $map->{$^O} || $map->{default} ;

@tests = (
    { 
        name => 'debian-bug-671367' ,
        setup => {
            'system_sshd_config' => $map,
        },
        load_warnings => undef , # some weird warnings pop up in Perl smoke tests with perl 5.15.9
        check => { 
            'AuthorizedKeysFile:0' => '/etc/ssh/userkeys/%u',
            'AuthorizedKeysFile:1' => '/var/lib/misc/userkeys2/%u',
        },
        file_contents_like => {
            $target , qr!/etc/ssh/userkeys/%u /var/lib/misc/userkeys2/%u! ,
        }
    },
);

1;
