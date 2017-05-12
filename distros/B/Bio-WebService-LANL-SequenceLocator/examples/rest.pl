#!/usr/bin/env perl
use strict;
use warnings;

use JSON qw< decode_json >;
use LWP::UserAgent;

my $agent    = LWP::UserAgent->new( agent => 'you@example.com' );
my $response = $agent->post(
    "https://indra.mullins.microbiol.washington.edu/locate-sequence/within/hiv" => [
        sequence => "TCATTATATAATACAGTAGCAACCCTCTATTGTGTGCATCAAAGG",
    ],
);
unless ($response->is_success) {
    die "Request failed: ", $response->status_line, "\n",
        $response->decoded_content;
}
my $results = decode_json( $response->decoded_content );

# $results is now an array ref, like the JSON above
print $results->[0]{polyprotein}, "\n";
