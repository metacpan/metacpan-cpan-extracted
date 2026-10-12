use v5.40;
use feature 'class';
no warnings 'experimental::class';
use lib '../lib', '../../At.pm/lib';
use Bluesky;
use JSON::PP;
my $video = 'C:\Users\r\Downloads\720p.mp4';
my $b     = Bluesky->new;
$b->ensure_auth( handle => 'atperl.bsky.social', scope => 'atproto transition:generic' );
my $job = $b->uploadVideoJob( $video, 'video/mp4', did => $b->did, name => '720p.mp4' );

if ( builtin::blessed($job) && $job->isa('At::Error') ) {
    print "UPLOAD ERROR: $job\n";
    exit 1;
}
print "upload jobStatus: ", JSON::PP->new->canonical->encode($job), "\n";
my $jobId = $job->{jobId};
unless ($jobId) { print "no jobId\n"; exit 1 }
for my $i ( 1 .. 30 ) {
    my $status = $b->getVideoJobStatus($jobId);
    if ( builtin::blessed($status) && $status->isa('At::Error') ) { print "status error: $status\n"; sleep 2; next }
    printf "poll %2d state=%s progress=%s\n", $i, $status->{state} // '?', $status->{progress} // '-';
    if ( ( $status->{state} // '' ) eq 'JOB_STATE_COMPLETED' ) {
        print "full status: ", JSON::PP->new->canonical->encode($status), "\n";
        print "blob: ", ( $status->{blob} ? JSON::PP->new->canonical->encode( $status->{blob} ) : '(none)' ), "\n";
        last;
    }
    sleep 2;
}
