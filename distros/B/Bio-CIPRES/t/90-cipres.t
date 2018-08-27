#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Net::Ping;
use List::Util qw/first/;
use LWP::Simple;

use Bio::CIPRES;
use Bio::CIPRES::Error qw/:constants/;

# The first SKIP block contains limited tests which can be run without valid
# credentials. Mostly this checks that the server connection can be initiated
# and that the expected Error objects are returned on failure;

SKIP: {
   
    my $p = Net::Ping->new();

    # Check for necessary network connections and skip otherwise
    skip "CIPRES server not reachable", 7 if (! $p->ping($Bio::CIPRES::SERVER));
    skip "CIPRES httpd not reachable", 7
        if (! is_success(getprint("https://$Bio::CIPRES::SERVER")));

    # direct config with bogus credentials
    my $ua = Bio::CIPRES->new(
        user   => 'foo',
        pass   => 'bar',
        app_id => 'baz',
    );

    isa_ok( $ua, 'Bio::CIPRES' );
    ok( $ua->{cfg}->{user} eq 'foo' );

    # config from file with bogus credentials
    $ua = Bio::CIPRES->new(
        conf => 't/test_data/cipres.conf',
    );

    isa_ok( $ua, 'Bio::CIPRES' );
    ok( $ua->{cfg}->{user} eq 'bar' );

    # job submission should fail with authentication error
    eval { $ua->submit_job() };
    ok( $@, "submit_job threw expected exception" );
    #diag( "NET: $@ $!\n" );
    isa_ok( $@, 'Bio::CIPRES::Error' );
    cmp_ok( $@,  '==', ERR_AUTHENTICATION, "exception == ERR_AUTHENTICATION");

}

# The second SKIP block contains more substantial tests that will run in a
# real config file is found. These will usually only be run on the developer's
# system.

SKIP: {

    # Skip the rest if no user credentials found
    skip "No valid credentials available", 21 if (! -r "$ENV{HOME}/.cipres");

    # Good (testing) credentials
    my $ua = Bio::CIPRES->new(
        conf => "$ENV{HOME}/.cipres",
    );

    # try to fetch non-existant job
    eval { $ua->get_job('foobar') };
    ok( $@, "get_job() threw expected exception" );
    isa_ok( $@, 'Bio::CIPRES::Error' );
    cmp_ok( $@,  '==', ERR_NOT_FOUND, "exception == ERR_NOT_FOUND");
    cmp_ok( "$@",  'eq', "Job not found.", "exception == ERR_NOT_FOUND");

    # submit bad job
    eval {
        my $job = $ua->submit_job(
            'tool'                => 'CLUSTALW',
            'input.infile_'       => ">test_seq_1\nAATGCC\n>test_seq_2\nAAATGCG\n",
            'vparam.runtime_'     => '0.5',
            'bad_param_foo'       => 'bar',
        );
    };
    ok( $@, "submit_job() threw expected exception" );
    isa_ok( $@, 'Bio::CIPRES::Error' );
    cmp_ok( $@,  '==', ERR_FORM_VALIDATION, "exception == ERR_FORM_VALIDATION");

    # submit good job
    my $job = $ua->submit_job(
        'tool'                => 'CLUSTALW',
        'input.infile_'       => ">test_seq_1\nAATGCC\n>test_seq_2\nAAATGCG\n",
        'vparam.runtime_'     => '0.5',
    );
    isa_ok( $job, 'Bio::CIPRES::Job' );

    # test get_job() as well as auto-stringification by fetching same job
    $job = $ua->get_job("$job");
    isa_ok( $job, 'Bio::CIPRES::Job' );

    # test list_jobs() by finding same job
    my @jobs = $ua->list_jobs();
    $job = first { "$_" eq "$job" } @jobs;
    isa_ok( $job, 'Bio::CIPRES::Job' );

    isa_ok( $job->submit_time, 'Time::Piece' );
   
    # wait for completion and check final status/results
    ok( $job->wait(1200), "wait() returned true" );
    is( $job->stage, 'COMPLETED', "returned expected job stage" );
    cmp_ok( $job->exit_code, '==', 0, "job return expected exit status" );

    ok(! $job->is_failed, "job not failed" );

    my ($result) = $job->outputs(name => 'infile.aln', group => 'aligfile');
    isa_ok( $result, 'Bio::CIPRES::Output' );
    cmp_ok( $result->size, '==', 114, "output correct size" );

    my $contents = $result->download;
    open my $foo, '>', 'foobarbaz';
    print {$foo} $contents;
    close $foo;
    like( $contents, qr/^test_seq_2\s+AAAT/mi, "returned expected job output" );

    my $stdout = $job->stdout;
    my $stderr = $job->stderr;
    ok( length  $stdout, "stdout has content" );
    ok( defined $stderr, "Stderr is defined"  );

    # try to clean up
    ok( $job->delete, "job deleted without error" );
}

done_testing();
exit;
