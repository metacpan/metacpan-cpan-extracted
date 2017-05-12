use strict;
use warnings;

use lib 'lib';
use Benchmark::Stopwatch;
use LWP::Simple;

my $sw = Benchmark::Stopwatch->new;

my @urls = (
    'http://www.yahoo.com/',      # in Alexa rank order
    'http://www.google.com/',     # as of 6 June 2006
    'http://www.msn.com/',        #
    'http://www.myspace.com/',    #
    'http://www.ebay.com/',       #
);

$sw->start;

foreach my $url (@urls) {
    print "Fetching '$url' ...\n";
    get($url);
    $sw->lap($url);
}

$sw->stop;

print "\n\n";
print $sw->summary;
