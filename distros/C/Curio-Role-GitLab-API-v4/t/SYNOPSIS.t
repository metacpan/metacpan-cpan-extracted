#!/usr/bin/env perl
BEGIN { $ENV{PERL_STRICTURES_EXTRA} = 0 }
use strictures 2;
use Test2::V0;

use lib 't/lib';

open( my $fh, '<', 'lib/Curio/Role/GitLab/API/v4.pm' );
my $content = do { local $/; <$fh> };
close $fh;

if ($content =~ m{=head1 SYNOPSIS\n\n\S.+?:\n\n(.+?)\n\S.+?:\n\n(.+?)\n=head1}s) {
    my @blocks = ($1, $2);
    my $count = 0;
    foreach my $block (@blocks) {
        $count++;
        local $@;
        my $ok = eval "$block; 1";
        die "Failed to run SYNOPSIS block #$count:\n$@" if !$ok;
    }
}

my $api = myapp_gitlab()->api();

isa_ok( $api, ['GitLab::API::v4'], 'got a gitlab api object' );

done_testing;
