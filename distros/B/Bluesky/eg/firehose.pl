# eg/firehose.pl - stream live events from the AT Protocol firehose.
#
#   perl firehose.pl [seconds]
#
# Requires Mojo::UserAgent; the HTTP::Tiny fallback cannot do WebSockets.
use v5.40;
use blib;
$|++;
use Bluesky;
use Mojo::IOLoop;
my $seconds = shift // 10;
my $bsky    = Bluesky->new;
my $count   = 0;
my $done    = 0;
my $fh      = $bsky->firehose(
    sub ( $header, $body, $err ) {
        return if $done;
        if ($err) { say "error: $err"; return }
        $count++;
        my $type   = ref $header eq 'HASH'                                                   ? ( $header->{t}            // '?' ) : '?';
        my $repo   = ref $body eq 'HASH'                                                     ? ( $body->{repo}           // '?' ) : '?';
        my $action = ref $body eq 'HASH' && ref $body->{ops} eq 'ARRAY' && @{ $body->{ops} } ? ( $body->{ops}[0]{action} // '?' ) : '-';
        say sprintf '%4d  %-12s %-8s %s', $count, $type, $action, $repo;
    }
);
say "Streaming the firehose for ${seconds}s (Ctrl-C to stop)...";
$fh->start;
Mojo::IOLoop->timer( $seconds => sub { $done = 1; Mojo::IOLoop->stop } );
Mojo::IOLoop->start;
say "Received $count events.";
