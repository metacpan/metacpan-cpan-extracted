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
subtest 'live' => sub {
    my $at = At->new( host => 'bsky.social' );

    # Do not run these tests; they might not be supported upstream...
    can_ok $at, $_ for qw[temp_checkSignupQueue temp_pushBlob temp_transferAccount temp_importRepo temp_requestPhoneVerification];
};
#
done_testing;
