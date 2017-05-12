#
# This file is part of Config-Model-OpenSsh
#
# This software is Copyright (c) 2014 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use Config::Model::BackendMgr;

# test loading layered config à la ssh_config

$home_for_test =
  $^O eq 'darwin'
  ? '/Users/joe'
  : '/home/joe';
Config::Model::BackendMgr::_set_test_home($home_for_test);

$model_to_test = "Ssh";

my @setup = (
    setup => {
        'system_ssh_config' => {
            'darwin'  => '/etc/ssh_config',
            'default' => '/etc/ssh/ssh_config',
        },
        'user_ssh_config' => "$home_for_test/.ssh/config"
    }
);

@tests = (
    {
        name => 'basic',
        @setup,
        check => [
            'Host:"*" Port' => {qw/mode layered value 22/},
            'Host:"*" Port' => '1022',

            # user value will completely override layered values
            'Host:"*" Ciphers' => { qw/mode layered value/, '' },
            'Host:"*" Ciphers' => { qw/mode user value/,    'aes192-cbc,aes128-cbc' },
            'Host:"*" Ciphers' => 'aes192-cbc,aes128-cbc',

            #'Host:"foo\.\*,\*\.bar"' => '',
            'Host:picosgw LocalForward:0 port' => 20022,
            'Host:picosgw LocalForward:0 host' => '10.3.244.4',
            'Host:picosgw LocalForward:1 ipv6' => 1,
            'Host:picosgw LocalForward:1 port' => 22080,
            'Host:picosgw LocalForward:1 host' => '2001:0db8:85a3:0000:0000:8a2e:0370:7334',
        ],
        verify_annotation => {
            ''                   => 'ssh global comment',
            'Host:"*" SendEnv'   => '  PermitLocalCommand no',
            'Host:"foo.*,*.bar"' => "foo bar big\ncomment",
        }
    },
    {
        name => 'legacy',
        @setup,
        load_check    => 'no',
        load_warnings => [ (qr/deprecated/) x 2, ],

    }
);

1;
