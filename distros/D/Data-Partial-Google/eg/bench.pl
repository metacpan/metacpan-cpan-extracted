#!perl
use strict;
use warnings;
use Data::Partial::Google;
use JSON::XS ();
use FindBin;
use Benchmark;

open my $fixture_fh, '<', "$FindBin::Bin/../t/activities.json" or die $!;

my $fixture = JSON::XS::decode_json(do { local $/; <$fixture_fh> });
my $mask = Data::Partial::Google->new('url,object(content,attachments/url)');

timethis(-3, sub {
		my $out = $mask->mask($fixture);
});
