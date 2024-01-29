use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Class qw[isa_ok can_ok];
#
skip_all 'Tests require Mojo::UserAgent' if !eval 'require Mojo::UserAgent';
skip_all 'Tests require Mojo::Promise'   if !eval 'require Mojo::Promise';
#
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
#
use At;
use At::Bluesky;
#
subtest 'live' => sub {
    my $at = At::Bluesky->new( identifier => 'atperl.bsky.social', password => 'ck2f-bqxl-h54l-xm3l' );

    # Do not run these tests... bsky.network doesn't support the endpoint and I don't know a service that does
    can_ok $at, $_ for qw[label_queryLabels label_subscribeLabels label_subscribeLabels_p];
};
#
done_testing;
