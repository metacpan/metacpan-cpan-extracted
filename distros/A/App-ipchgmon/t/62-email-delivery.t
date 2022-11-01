use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Email::Stuffer;
use FindBin qw( $RealBin );
use lib "$RealBin/../lib";

use App::ipchgmon;

# This is the basic test of send_email. A simple email is sent using a mock
# of the send() method.

my $rtn;

my $mockEmailStuffer = Test::MockModule->new('Email::Stuffer')
->redefine('send', sub{
    my $self = shift;
    $rtn  = $$self{'parts'}[0]{'body_raw'};
    $rtn .= $$self{'email'}{'header'}{'headers'}[4] . ': ';
    $rtn .= $$self{'email'}{'header'}{'headers'}[5] . "\n";
    $rtn .= $$self{'email'}{'header'}{'headers'}[6] . ': ';
    $rtn .= $$self{'email'}{'header'}{'headers'}[7] . "\n";
    $rtn .= $$self{'email'}{'header'}{'headers'}[8] . ': ';
    $rtn .= $$self{'email'}{'header'}{'headers'}[9] . "\n";
});

my @recipients = ('you@example.com');
$App::ipchgmon::opt_email = \@recipients;
$App::ipchgmon::opt_mailfrom = 'me@example.com';
$App::ipchgmon::opt_mailsubject = 'test';
$App::ipchgmon::opt_server = 'Test server';
App::ipchgmon::send_email('0.0.0.0');
like $rtn, qr(To: you), '"To" rendered correctly';
like $rtn, qr(From: me), '"From" rendered correctly';
like $rtn, qr(Subject: test), '"Subject" rendered correctly';
like $rtn, qr(Test server is now at 0\.0\.0\.0), 'Body rendered correctly';

done_testing();
