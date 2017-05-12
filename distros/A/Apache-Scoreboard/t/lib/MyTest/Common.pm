package MyTest::Common;

use strict;
use warnings FATAL => 'all';

use Apache::Scoreboard ();
use APR::Pool ();

use Apache::Test;
use Apache::TestUtil;
use Apache::TestTrace;
use Apache::TestRequest ();

use File::Spec::Functions qw(catfile);

# as we can't know ahead how many procs/workers are there, we can't
# ok each value, in which case we will just look for faults when their
# occur.

my $cfg = Apache::Test::config();
my $vars = $cfg->{vars};

my $store_file = catfile $vars->{documentroot}, "scoreboard";
my $hostport = Apache::TestRequest::hostport($cfg);
my $retrieve_url = "http://$hostport/scoreboard";

my @worker_score_scalar_props = 
    qw(access_count bytes_served
       client conn_bytes conn_count most_recent
       my_access_count my_bytes_served request req_time
       status thread_num tid);
# vhost is not available outside mod_perl, since it requires a call to
# an Apache method
push @worker_score_scalar_props, "vhost" if $ENV{MOD_PERL};

my @worker_score_dual_ctx_props = qw(
    times start_time stop_time
);

my @worker_score_dual_var_props = qw(status);

sub retrieve_url { return $retrieve_url }

sub num_of_tests {
    my $ntests = 16;
    $ntests += 2 if $ENV{MOD_PERL}; # deprecated constants
    return $ntests;
}

sub test1 {

    my $pool = APR::Pool->new;

    debug "PID: ", $$, " ppid:", getppid(), "\n";

    ### constants ###
    {
        t_debug "constants";
        # deprecated and available only under mod_perl
        if ($ENV{MOD_PERL}) {
            ok Apache::Const::SERVER_LIMIT;
            ok Apache::Const::THREAD_LIMIT;
        }

        ok Apache::Scoreboard::REMOTE_SCOREBOARD_TYPE;
    }

    ### the scoreboard image fetching methods ###

    # need to have two available workers, otherwise it'll hang
    # run the test with: -maxclients 2
    if ($ENV{MOD_PERL} && $vars->{maxclients} < 2) {
        die "maxclients needs to be 2 or higher";
    }

    my $image;
    # fetch the image via lwp and run a few basic tests
    {
        t_debug("fetching: $retrieve_url");
        $image = Apache::Scoreboard->fetch($pool, $retrieve_url);
        ok image_is_ok($image);

        t_debug("fetch_store/retrieve ($store_file)");
        Apache::Scoreboard->fetch_store($retrieve_url, $store_file);
        $image = Apache::Scoreboard->retrieve($pool, $store_file);
        ok image_is_ok($image);
    }

    # testing freeze+thaw / store+retrieve the scoreboard image
    {
        my $image = Apache::Scoreboard->fetch($pool, $retrieve_url);
        ok image_is_ok($image);

        t_debug "image freeze/thaw";
        my $frozen_image = $image->freeze;
        my $thawed_image = Apache::Scoreboard->thaw($pool, $frozen_image);
        ok image_is_ok($thawed_image);

        t_debug("image store/retrieve ($store_file)");
        Apache::Scoreboard->store($frozen_image, $store_file);
        $image = Apache::Scoreboard->retrieve($pool, $store_file);
        ok image_is_ok($image);
    }
}

sub test2 {
    my $image = shift;
    ### parents/workers iteration functions ###

    ok image_is_ok($image);

    t_debug "iterating over procs/workers";
    my $parent_ok      = 1;
    my $next_ok        = 1;
    my $next_live_ok   = 1;
    my $next_active_ok = 1;
    for (my $parent_score = $image->parent_score;
         $parent_score;
         $parent_score = $parent_score->next) {

        $parent_ok = 0 unless parent_score_is_ok($parent_score);

        my $pid = $parent_score->pid;
        t_debug "pid = $pid";

        # iterating over all workers for the given parent
        for (my $worker_score = $parent_score->worker_score;
                $worker_score;
                $worker_score = $parent_score->next_worker_score($worker_score)
            ) {
            $next_ok = 0 unless worker_score_is_ok($worker_score);
        }

        # iterating over only live workers for the given parent
        for (my $worker_score = $parent_score->worker_score;
                $worker_score;
                $worker_score = $parent_score->next_live_worker_score($worker_score)
            ) {
            $next_live_ok = 0 unless worker_score_is_ok($worker_score);
        }


        # iterating over only active workers for the given parent
        for (my $worker_score = $parent_score->worker_score;
                $worker_score;
                $worker_score = $parent_score->next_active_worker_score($worker_score)
            ) {
            $next_active_ok = 0 unless worker_score_is_ok($worker_score);
        }
    }

    t_debug "parent ok";
    ok $parent_ok;
    t_debug "iterating over all workers";
    ok $next_ok;
    t_debug "iterating over all live workers";
    ok $next_live_ok;
    t_debug "iterating over all active workers";
    ok $next_active_ok;


    ### other scoreboard image accessors ###

    my @pids = @{ $image->pids };
    t_debug "pids: @pids";
    ok @pids;

    my @thread_numbers = @{ $image->thread_numbers(0) };
    t_debug "thread_numbers: @thread_numbers";
    ok @thread_numbers;

    my $up_time = $image->up_time;
    t_debug "up_time: $up_time";
    ok $up_time >= 0; # can be 0 if tested too fast

    my $worker_score = $image->worker_score(0, 0);
    ok $worker_score;

    my $pid = $pids[0];

    my $self_parent_idx = $image->parent_idx_by_pid($pid);
    t_debug "pid: $$, self_parent_idx: $self_parent_idx";
    my $self_parent_score = $image->parent_score($self_parent_idx);
    t_debug "parent_idx_by_pid";
    # parent_score_is_ok internally calls worker_score_is_ok on the
    # first worker score
    ok parent_score_is_ok($self_parent_score);

}

# try to access various underlying datastructures to test that the
# image is valid
sub image_is_ok {
    my ($image) = shift;
    my $status = 1;
    $status = 0 unless $image && 
        ref($image) eq 'Apache::Scoreboard' &&
        $image->pids &&
        $image->worker_score(0, 0)->status &&
        $image->parent_score &&
        $image->parent_score->worker_score->vhost &&
        $image->server_limit && 
        $image->thread_limit;

    # check that we don't segfault here
    #for (my $proc = $image->parent; $proc; $proc = $proc->next) {
    #    my $pid = $proc->pid;
    #}

    return $status;
}

# check that all worker_score props return something
sub parent_score_is_ok {
    my ($parent_score) = shift;

    my $ok = 1;

    $ok = 0 unless $parent_score && $parent_score->pid;

    # check the first worker
    my $worker_score = $parent_score->worker_score;
    $ok = 0 unless worker_score_is_ok($worker_score);

    return $ok;
}

# check that all worker_score props return something
sub worker_score_is_ok {
    my ($worker_score) = shift;

    return 0 unless $worker_score;

    my $ok = 1;
    for (@worker_score_dual_ctx_props) {
        my $res = $worker_score->$_();
        unless (defined $res) {
            $ok = 0;
            warn "$_() failed: undefined\n";
        }

        my @res = $worker_score->$_();
        unless (@res) {
            $ok = 0;
            warn "$_() failed: empty list\n";
        }
    }

    # status: dual var
    {
        my $res = $worker_score->status();
        unless ($res/1 == $res) {
            $ok = 0;
            my $x = $res + 0;
            warn "status()-in-numerical-context failed: " .
                "not integer number: [$x]\n";
        }
        unless ($res =~ /^[\w\.]$/) {
            $ok = 0;
            warn "status()-in-string-context failed: got [$res]\n";
            warn "access count: " , $worker_score->access_count(), "\n";
        }
    }

    for (@worker_score_scalar_props) {
        my $res = $worker_score->$_();
        unless (defined $res) {
            $ok = 0;
            warn "$_() failed: undefined\n";
        }
    }

    return $ok;
}

1;
