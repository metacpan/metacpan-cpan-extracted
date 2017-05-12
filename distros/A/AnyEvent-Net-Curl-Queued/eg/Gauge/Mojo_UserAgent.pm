package Gauge::Mojo_UserAgent;
use strict;
use utf8;
use warnings qw(all);

use Any::Moose;
with qw(Gauge::Role);

use Mojolicious;

my $loop;
BEGIN { $loop = Mojo::IOLoop->singleton }

sub run {
    my ($self) = @_;

    # stolen from http://blogs.perl.org/users/stas/2013/01/web-scraping-with-modern-perl-part-1.html

    # User agent following up to 5 redirects
    my $ua = Mojo::UserAgent->new(name => qq(Mojo::UserAgent/$Mojolicious::VERSION));
    my @urls = map { Mojo::URL->new($_) } @{$self->queue};

    # Disable compression
    $ua->on(start => sub {
        my (undef, $tx) = @_;
        $tx->req->headers->header(q(Accept-Encoding) => q(identity));
    });

    # Keep track of active connections
    my $active = 0;

    # Update queue ASAP
    my $id = $loop->recurring(
        0 => sub {
            for ($active + 1 .. $self->parallel) {

                # Dequeue or halt if there are no active crawlers anymore
                return ($active or $loop->stop)
                    unless my $url = shift @urls;

                # Fetch non-blocking just by adding
                # a callback and marking as active
                ++$active;
                $ua->get($url => sub {
                    # Deactivate
                    --$active;

                    return;
                });
            }
        }
    );

    # Start event loop if necessary
    $loop->start unless $loop->is_running;

    # Shutdown queue watcher
    $loop->remove($id);

    return;
}

1;
