use v5.42;
use lib '../lib', 'lib';
use At;
use Mojo::IOLoop;
$|++;
#
my $at = At->new();
say 'At.pm Mojo Firehose Demo';
say "Listening for live commits on the AT Protocol network...";
my $fh = $at->firehose(
    sub ( $header, $body, $err ) {
        if ($err) {
            warn "Firehose Error: $err\n";
            return;
        }

        # Extract commit info
        if ( $header->{t} eq '#commit' ) {
            my $repo = $body->{repo};
            my $ops  = $body->{ops} // [];
            for my $op (@$ops) {
                printf "[%-15s] Repo: %s | Path: %s\n", $op->{action}, $repo, $op->{path};
            }
        }
    }
);
$fh->start();

# Start the Mojo event loop
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

=head1 NAME

firehose.pl - Real-time Firehose Consumer Example

=head1 SYNOPSIS

    perl eg/firehose.pl

=head1 DESCRIPTION

This script demonstrates how to consume the AT Protocol "Firehose" (subscription
to repo updates). It uses the C<At::firehose( ... )> helper, which relies on a
non-blocking user agent to stream events.

It listens for C<#commit> events and prints the repository and operation path
for every new event on the network.

=cut
