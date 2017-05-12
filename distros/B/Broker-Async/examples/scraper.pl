#!/usr/bin/env perl
use Broker::Async;
use Future;
use Future::HTTP;
use Time::HiRes qw(time);
use AE;
use AnyEvent;
use Future::HTTP::AnyEvent;

my ($throttle, @urls) = @ARGV;

my $ua = Future::HTTP->new;
my $scraper = sub { warn "> starting $_[0]\n"; $ua->http_get(@_) };
my $broker  = Broker::Async->new(
    workers => [{code => $scraper, concurrency => $throttle}],
);

my @results;
for my $url (@urls) {
    push @results, $broker->do($url)->on_ready(sub{
        my ($body, $headers) = $_[0]->get;
        warn "< finished getting $url: status - $headers->{Status}\n";
    });
}

warn "- waiting for results\n";
Future->wait_all(@results)->get;
warn "- finished getting all results\n";
