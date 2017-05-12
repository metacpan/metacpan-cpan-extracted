use Test::More qw/no_plan/;

BEGIN {
    use_ok('Catalyst::JobQueue::Job');
}

$job = Catalyst::JobQueue::Job->new({ type => 'cron' });

isa_ok($job, 'Catalyst::JobQueue::Job');

$ID = $job->ID;

like($ID, qr/^\d+$/, 'check numeric ID');
