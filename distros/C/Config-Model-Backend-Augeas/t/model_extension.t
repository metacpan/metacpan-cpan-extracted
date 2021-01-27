#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use Test::More ;

# this test checks that the model extension 
# (e.g. lib/Config/Model/models/Itself/Class.d/augeas-backend.pl)
# containing the "meta" model for Augeas backend can be loaded by
# Config::Model::Itself and used

# I.e.
# Load Config::Model::Itself
# check that extension located in dir mentioned above is installed
# load a Sshd model that use augeas backend


use ExtUtils::testlib;
use Config::Model ;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Config::Model::Itself 2.012;

my ($meta_model, $trace) = init_test();

my $meta_inst = $meta_model->instance(
    root_class_name => 'Itself::Model',
    instance_name   => 'meta',
);
ok($meta_inst,"Loaded Itself::Model") ;

my $meta_root = $meta_inst->config_root ;

my %ssh_model ;

# avoid unordered hash warning
$ssh_model{class}{__order} = ['MasterModel::SshdWithAugeas'];

$ssh_model{class}{'MasterModel::SshdWithAugeas'} = {

        'rw_config' => {
            backend         => 'Augeas',
            # commentnfig_dir      => '/etc/ssh',
            file            => 'sshd_config',
            sequential_lens => [qw/HostKey Subsystem Match/],
        },

        element => [
            'AcceptEnv',
            {
                'cargo' => {
                    'value_type' => 'uniline',
                    'type'       => 'leaf'
                },
                'type' => 'list',
            },
            'HostbasedAuthentication',
            {
                'value_type' => 'boolean',
                'type'       => 'leaf',
            },
            'HostKey',
            {
                'cargo' => {
                    'value_type' => 'uniline',
                    'type'       => 'leaf'
                },
                'type' => 'list',
            },
            'Subsystem',
            {
                'cargo' => {
                    'value_type' => 'uniline',
                    'mandatory'  => '1',
                    'type'       => 'leaf'
                },
                'type'       => 'hash',
                'index_type' => 'string'
            },
        ]
    } ;


$meta_root->load_data(\%ssh_model);

print $meta_root->dump_tree if $trace;

# kind of not necessary since load_data aboce will fail if the model extension is
# not loaded
my $backend = $meta_root->grab("class:MasterModel::SshdWithAugeas rw_config backend") ;
like(
    join( ',', $backend->get_choice),
    qr/Augeas/,
    "test that augeas backend is part of backend choice"
) ;

done_testing();
