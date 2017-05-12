#!/usr/bin/env perl
use strict;
use warnings;
use AnyEvent::Beanstalk;
use Mojo::UserAgent;
use JSON;
use Data::Dumper;

my @urls = ();

if (@ARGV) {
    push @urls, @ARGV;
}

else {
    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->get('http://www.uroulette.com/');

    $tx->res->dom->find('blockquote a[href]')->each(sub { push @urls, shift->{href} });
}

my $method = "GET";

my $bs = AnyEvent::Beanstalk->new
  (server => 'localhost',
   encoder => sub { encode_json(shift) });

$bs->use('web-jobs')->recv;

for my $url ( @urls ) {
    my $job = $bs->put({ priority => 100,
                         ttr      => 15,
                         delay    => 1,
                         encode   => { url => $url,
                                       method => $method }})->recv;

    print STDERR "job added to queue (" . $job->id . "): " . Dumper($job->data);
}

exit;
