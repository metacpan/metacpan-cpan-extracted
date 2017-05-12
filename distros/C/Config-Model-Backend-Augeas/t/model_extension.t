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
use Log::Log4perl qw(:easy :levels) ;
use Config::Model ;

no warnings qw(once);

eval { require Config::Model::Itself ;} ;
if ( $@ ) {
    plan skip_all => 'Config::Model::Itself is not installed';
}
else {
    plan tests => 3;
}

my $arg = shift || '';
my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;

my $home = $ENV{HOME} || "";
my $log4perl_user_conf_file = "$home/.log4config-model";

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($log ? $WARN: $ERROR);
}

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

my $meta_model = Config::Model -> new ( ) ;# model_dir => '.' );

ok(1,"compiled");

my $meta_inst = $meta_model->instance(
    root_class_name => 'Itself::Model',
    instance_name   => 'meta',
);
ok($meta_inst,"Loaded Itself::Model") ;

my $meta_root = $meta_inst->config_root ;

my %ssh_model;

$ssh_model{class}{'MasterModel::SshdWithAugeas'} = {

        'read_config' => [
            {
                backend         => 'Augeas',
                config_dir      => '/etc/ssh',
                file            => 'sshd_config',
                sequential_lens => [qw/HostKey Subsystem Match/],
            },
            {
                backend     => 'perl_file',
                config_dir  => '/etc/ssh',
                auto_create => 1,
            },
        ],

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
my $backend = $meta_root->grab("class:MasterModel::SshdWithAugeas read_config:0 backend") ;
like(
    join( ',', $backend->get_choice),
    qr/Augeas/,
    "test that augeas backend is part of backend choice"
) ;

