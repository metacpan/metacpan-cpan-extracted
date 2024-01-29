use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Class qw[isa_ok can_ok];
#
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
#
use At;
#
isa_ok( At::Lexicon::com::atproto::moderation::reasonType->new( '$type' => 'com.atproto.moderation.defs#reasonSpam' ),
    ['At::Lexicon::com::atproto::moderation::reasonType'] );
subtest 'live' => sub {
    my $at = At->new( host => 'bsky.social' );

    # Do not run these tests...
    can_ok $at, $_ for qw[moderation_createReport];
};
#
done_testing;
