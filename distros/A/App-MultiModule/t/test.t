#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use POSIX ":sys_wait_h";
use Test::More skip_all => 'needs more development before I can unleash this on
CPAN testers';
use IPC::Transit;
use Data::Dumper;

use App::MultiModule::API;


BEGIN {
#    plan skip_all => 'internal testing only';
    use_ok('App::MultiModule') || die "Failed to load App::MultiModule\n";
    use_ok('App::MultiModule::Test') || die "Failed to load App::MultiModule::Test\n";
    use_ok('App::MultiModule::Test::StatefulStream') || die "Failed to load App::MultiModule::Test::StatefulStream\n";
}

App::MultiModule::Test::begin();

ok my $daemon_pid = App::MultiModule::Test::run_program('-q tqueue -p MultiModuleTest::');

my $config = {
    '.multimodule' => {
        config => {
            MultiModule => {
                intervals => {
                    save_state => 10,
                },
            },
            OtherExternalModule => {},
            OtherModule => {},
            SmartMerge => {
                merge_instance => 'instance',
            },
            Thresholds => {
            },
            LinuxCollect => {},
            TransitGateway => {},
            Graphite => {},
            Inform => {},
            MongoDB => {},
            Buckets => {
#                is_external => 1,
            },
            Dedup => {},
            Router => {  #router config
                routes => [
                    {   match => {
                            collection_object => 'diskstats_info',
                        },
                        forwards => [
                            {   qname => 'test_out' }
                        ],
                    },{ match => {
                            source => 'MultiModule',
                            window_width => 60,
                        },
                        forwards => [
                            {   qname => 'Graphite' }
                        ],
                        transform => {
                            local_hostname => ' specials/$local_vars->{local_hostname}',
                            inform_instance => ' specials/"internal_monitoring:$local_vars->{local_hostname}::$message->{bucket_name}"',
                            graphite_metric_path => ' specials/"internal_monitoring.$local_vars->{local_hostname}.$message->{bucket_name}"',
                            graphite_metric_value => ' specials/$message->{return_value}',
                        },
                    }
                ],
            }
        },
    }
};

ok IPC::Transit::send(qname => 'tqueue', message => $config);

sleep 3600;

#ask it to go away nicely
ok IPC::Transit::send(qname => 'tqueue', message => {
    '.multimodule' => {
        control => [
            {   type => 'cleanly_exit',
                exit_externals => 1,
            }
        ],
    }
});

sleep 6;
ok waitpid($daemon_pid, WNOHANG) == $daemon_pid;
ok not kill 9, $daemon_pid;


App::MultiModule::Test::finish();

done_testing();
