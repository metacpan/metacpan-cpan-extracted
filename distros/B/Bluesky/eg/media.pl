# eg/media.pl - a complete media posting demo that creates...
#
#   - an image post (app.bsky.embed.images) with alt text and aspectRatio
#   - a gallery post (app.bsky.embed.gallery) with per-item alt/aspectRatio
#   - a video post: upload through the video service, wait for the processed
#      blob, then embed it (app.bsky.embed.video) with alt, aspectRatio,
#      captions, and presentation
#
#   perl media.pl [image.jpg] [clip.mp4]
#
# Paths default to the files used while developing this module.
use v5.40;
use feature 'class';
no warnings 'experimental::class';
use lib '../lib', '../../At.pm/lib';
$|++;
use Bluesky;
my $IMAGE = shift // 'C:\Users\r\Downloads\258-536x354.jpg';
my $VIDEO = shift // 'C:\Users\r\Downloads\720p.mp4';

# ensure_auth logs in once and reuses (and refreshes) the saved session.json.
my $bsky = Bluesky->new->ensure_auth( handle => 'atperl.bsky.social', scope => 'atproto transition:generic transition:chat.bsky' );

# A WebVTT caption track attached to the video. uploadVideoCaption accepts a path or the raw VTT bytes.
my $captions_en = <<'VTT';
WEBVTT

00:00.000 --> 00:02.000
Hello from Perl!

00:02.000 --> 00:04.000
This clip was uploaded to the Bluesky video service.
VTT

# Images (app.bsky.embed.images): up to 4 items. Each item is
#    { image, alt, aspectRatio } where aspectRatio is { width, height }.
my $image_post = $bsky->createPost(
    text  => 'Posted with an image from Perl! #perl',
    lang  => ['en'],
    embed => {
        images => [
            { image => $IMAGE, alt => 'A demo image posted from Perl', aspectRatio => { width => 536, height => 354 } },
            { image => $IMAGE, alt => 'The same demo image, no aspectRatio this time' }
        ]
    }
);
say 'image post uri: ' . ( $image_post->{uri} // '?' );

# Gallery (app.bsky.embed.gallery): the schema allows up to 20 items, but
#    clients currently soft-limit authoring to 10. Each item is
#    { image, alt, aspectRatio } (aspectRatio is required for gallery items).
my $gallery_post = $bsky->createPost(
    text  => 'A little gallery from Perl.',
    lang  => ['en'],
    embed => {
        gallery => [
            { image => $IMAGE, alt => 'Gallery image one',   aspectRatio => { width => 536, height => 354 } },
            { image => $IMAGE, alt => 'Gallery image two',   aspectRatio => { width => 4,   height => 3 } },
            { image => $IMAGE, alt => 'Gallery image three', aspectRatio => { width => 1,   height => 1 } }
        ]
    }
);
say 'gallery post uri: ' . ( $gallery_post->{uri} // '?' );

# Video (app.bsky.embed.video): run the video-service processing job, poll
#    for the processed blob, then build and embed the video record.
say "uploading $VIDEO to the video service ...";
my $job = $bsky->uploadVideoJob( $VIDEO, 'video/mp4', did => $bsky->did, name => '720p.mp4' );
die "Video upload failed: $job\n" if builtin::blessed($job) && $job->isa('At::Error');
my $jobId = $job->{jobId} or die "No jobId returned\n";
say "job $jobId: state=" . ( $job->{state} // '?' ) . ( $job->{error} ? " ($job->{error})" : '' );

# Poll until the job exposes the processed blob. An already_exists job still
# yields the blob from getVideoJobStatus.
my $blob;
for my $i ( 1 .. 30 ) {
    my $status = $bsky->getVideoJobStatus($jobId);
    if ( builtin::blessed($status) && $status->isa('At::Error') ) {
        say "job status error: $status";
        sleep 2;
        next;
    }
    printf "poll %2d state=%s progress=%s\n", $i, $status->{state} // '?', $status->{progress} // '-';
    if ( $blob = $status->{blob} ) {last}
    die 'Video job failed: ' . ( $status->{message} // $status->{state} // '?' ) . "\n" if ( $status->{state} // '' ) eq 'JOB_STATE_FAILED';
    sleep 2;
}
$blob or die "Timed out waiting for video processing\n";
say 'processed blob: ' . ( $blob->{ref}{'$link'} // $blob->{cid} // '?' );

# videoEmbed wraps the blob with all app.bsky.embed.video options.
my $embed = $bsky->videoEmbed(
    $blob,
    alt          => 'A short 720p test clip posted from Perl',
    aspectRatio  => { width => 1280, height => 720 },
    presentation => 'default',                                   # or 'gif'
    captions     => { en => $captions_en }
);

# createPost accepts a fully-built embed (a hashref carrying $type) as-is.
my $video_post
    = $bsky->createPost( text => 'A video uploaded through the Bluesky video service and posted from Perl.', lang => ['en'], embed => $embed );
say 'video post uri: ' . ( $video_post->{uri} // '?' );
say 'done.';
