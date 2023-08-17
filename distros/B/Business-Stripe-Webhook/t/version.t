#!/usr/bin/perl
use warnings;
use strict;
use Test::More;

use Business::Stripe::Webhook;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $code_version = $Business::Stripe::Webhook::VERSION;
ok($code_version, 'version set');

ok(open(my $source, '<', $INC{'Business/Stripe/Webhook.pm'}), 'open the source');

my $in_version;
while (<$source>) {
    if (/^=head1 VERSION/) {
        $in_version = 1;
    } elsif (/^=head1/) {
        undef $in_version;
    }
    if ($in_version && /^Version ([0-9.]+)/) {
        is($code_version, $1, 'pod version');
    }
}

done_testing();
