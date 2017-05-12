#!env perl

use strict;
use warnings FATAL => 'all';
use IPC::Transit;
use File::Slurp;
use File::Temp qw/tempfile tempdir/;
use Data::Dumper;
use POSIX ":sys_wait_h";
use Test::More;
use lib '../lib';

BEGIN {
if(not $ENV{HAS_POSTGRES}) {
    ok 1, 'need postgres to be running to test.  Set HAS_POSTGRES environmental to enable tests.';
    done_testing();
    exit 0;
}
}

use_ok('App::MultiModule::Tasks::DocGateway');

BEGIN {
    use_ok('App::MultiModule') || die "Failed to load App::MultiModule\n";
    use_ok('App::MultiModule::Test') || die "Failed to load App::MultiModule::Test\n";
    use_ok('App::MultiModule::Test::DocGateway') || die "Failed to load App::MultiModule::Test::DocGateway\n";
    use_ok('Postgres::Mongo::Test') || die "Failed to load Postgres::Mongo::Test\n";
}

App::MultiModule::Test::begin();
App::MultiModule::Test::DocGateway::_begin();

our ($c, $testDBName, $testCollectionName) = Postgres::Mongo::Test::get_stuff();


my (undef, $errors_log) = tempfile();
my $args = "-q tqueue -p MultiModuleTest:: -o error:$errors_log";
ok my $daemon_pid = App::MultiModule::Test::run_program($args), 'run_program';
END { #just to be damn sure
    kill 9, $daemon_pid;
    unlink $errors_log;
};

my $config = {
    '.multimodule' => {
        config => {
            DocGateway => {
            },
            MultiModule => {
            },
            Router => {  #router config
                routes => [
                    {   match => {
                            source => 'DocGateway'
                        },
                        forwards => [
                            {   qname => 'test_out' }
                        ],
                    }
                ],
            }
        },
    }
};
ok IPC::Transit::send(qname => 'tqueue', message => $config), 'sent config';

sub message_is {
    my $test_name = shift;
    my $expected = shift;
    my $deletes = shift;
    my $message = eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 22;
        return IPC::Transit::receive(qname => 'test_out');
    };
    alarm 0;
    my $err = $@;
    ok(!$err, "no exception for $test_name");
    if($err) {
        print STDERR "\$get_msg failed: $@\n";
        return undef;
    }
    delete $message->{$_} for @$deletes;
    is_deeply($message, $expected, $test_name);
}

sub doc_send {
    my $message = shift;
    $message->{document_database} = $testDBName;
    $message->{document_collection} = $testCollectionName;
    IPC::Transit::send(qname => 'DocGateway', message => $message);
}
#make sure empty collection is empty
doc_send({
    document_method => 'find',
    document_filter => { a => 'b' }
});
message_is(
    'make sure empty collection is empty',
    {
        document_method => 'find',
        document_database => $testDBName,
        document_collection => $testCollectionName,
        source => 'DocGateway',
        document_filter => {
            a => 'b',
        },
        document_returns => [],
    },
    ['.ipc_transit_meta']
);

#add one doc and make sure it's there
doc_send({
    document_method => 'insert',
    a => 'b',
    this => 'that',
});
doc_send({
    document_method => 'find',
    document_filter => { a => 'b' },
});
message_is(
    'single doc added and found',
    {
        document_method => 'find',
        source => 'DocGateway',
        document_database => $testDBName,
        document_collection => $testCollectionName,
        document_filter => {
            a => 'b',
        },
        document_returns => [
            {   a => 'b',
                document_method => 'insert',
                this => 'that',
                document_database => $testDBName,
                document_collection => $testCollectionName,
            }
        ],
    },
    ['.ipc_transit_meta']
);


#remove only doc and make sure it is gone
doc_send({
    document_method => 'remove',
    document_filter => { a => 'b' },
});
doc_send({
    document_method => 'find',
    document_filter => { a => 'b' }
});
message_is(
    'remove only doc and make sure it is gone',
    {
        source => 'DocGateway',
        document_database => $testDBName,
        document_collection => $testCollectionName,
        document_method => 'find',
        document_filter => {
            a => 'b',
        },
        document_returns => [],
    },
    ['.ipc_transit_meta']
);


ok -z $errors_log;
sleep 5;
ok IPC::Transit::send(qname => 'tqueue', message => {
    '.multimodule' => {
        control => [
            {   type => 'cleanly_exit',
                exit_externals => 1,
            }
        ],
    }
}), 'sent program exit request';

sleep 6;
ok waitpid($daemon_pid, WNOHANG) == $daemon_pid, 'waitpid';
ok !kill(9, $daemon_pid), 'program exited';

App::MultiModule::Test::finish();
App::MultiModule::Test::DocGateway::_finish();

done_testing();
