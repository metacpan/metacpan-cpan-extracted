#!perl -wT
# $Id: /local/CPAN/AxKit-XSP-Minisession/t/003_pod_coverage.t 1418 2005-03-05T18:07:22.924154Z claco  $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan skip_all =>
    'Test::Pod::Coverage 1.04 required for testing pod coverage' if $@;

plan tests => 1;

my $trustme = { also_private => [qr/^(parse_.*|start_document)$/] };
pod_coverage_ok( 'AxKit::XSP::Minisession', $trustme );
