# -*- mode: cperl -*-
use Test::More;
eval "use 5.00504";
plan skip_all => "perl 5.00504 required for this test" if $@;
eval "use Test::Pod::Coverage 0.18"; # 0.15 was misbehaving according to David Cantrell
plan skip_all => "Test::Pod::Coverage 0.18 required for testing pod coverage" if $@;
plan tests => 1;
my $trustme = { trustme => [ qw{
                                ckcmp
                                investigate
                                makehashref
                              }]
              };
pod_coverage_ok( "CPAN::Checksums", $trustme );
