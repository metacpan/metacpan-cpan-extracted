use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Text::CSV qw (csv);
use Email::Stuffer;
use Regexp::Common qw(net);
use FindBin qw( $RealBin );
use lib "$RealBin/../lib";

use App::ipchgmon;

# This exercises check_dns, but sets the ipv4 and ipv6 options to check that
# the right ones are ignored at the right time. Emails are mocked and the
# output tested.

my $rtn = '';# Used to capture the contents of the object

# Mock the send() method
my $mockEmailStuffer = Test::MockModule->new('Email::Stuffer')
->redefine('send', sub{
    my $self = shift;
    $rtn .= $$self{'parts'}[0]{'body_raw'};
    $rtn .= $$self{'email'}{'header'}{'headers'}[4] . ': ';
    $rtn .= $$self{'email'}{'header'}{'headers'}[5] . "\n";
    $rtn .= $$self{'email'}{'header'}{'headers'}[6] . ': ';
    $rtn .= $$self{'email'}{'header'}{'headers'}[7] . "\n";
    $rtn .= $$self{'email'}{'header'}{'headers'}[8] . ': ';
    $rtn .= $$self{'email'}{'header'}{'headers'}[9] . "\n";
});

# set options that would have been passed from the command line in production
my @recipients = ('dnsto@example.com');
$App::ipchgmon::opt_email = \@recipients;
$App::ipchgmon::opt_mailfrom = 'dnsfrom@example.com';
$App::ipchgmon::opt_mailsubject = 'DNS test';

# Build the aoaref
my $csv = Text::CSV->new();
my ($aoaref, @fields);
$csv->combine("11.11.11.11");
push @fields, $csv->string();
$csv->combine("2022-08-28T00:00:00Z");
push @fields, $csv->string();
push @$aoaref, [@fields];
undef @fields;
$csv->combine("B::0");
push @fields, $csv->string();
$csv->combine("2022-08-28T00:00:00Z");
push @fields, $csv->string();
push @$aoaref, [@fields];

# Test IPv4 only
$App::ipchgmon::opt_4 = 1;
$App::ipchgmon::opt_6 = 0;
my $dnsname = 'example.com';
App::ipchgmon::check_dns($dnsname, $aoaref);
test_email_sent(1, 1, 0);

# Test both
$rtn = '';
$App::ipchgmon::opt_6 = 1;
App::ipchgmon::check_dns($dnsname, $aoaref);
test_email_sent(2, 1, 1);

# Test IPv6 only
$rtn = '';
$App::ipchgmon::opt_4 = 0;
App::ipchgmon::check_dns($dnsname, $aoaref);
test_email_sent(1, 0, 1);

done_testing();

sub test_email_sent {
    my ($n, $opt4, $opt6) = @_;
    like $rtn, qr(To: dnsto\@example.com), '"To" rendered correctly';
    like $rtn, qr(From: dnsfrom\@example.com), '"From" rendered correctly';
    like $rtn, qr(Subject: DNS test), '"Subject" rendered correctly';
    like $rtn, qr(example\.com has moved to), 'Body rendered correctly';
    my $count =()= ($rtn =~ m/dnsto\@example\.com/gms);
    is $count, $n, "$n destination address(es) found";
    $count =()= ($rtn =~ m/From: dnsfrom\@example\.com/gms);
    is $count, $n, "$n source address(es) found";
    $count =()= ($rtn =~ m/Subject: DNS test/gms);
    is $count, $n, "$n subject(s) found";
    $count =()= ($rtn =~ m/example\.com has moved to/gms);
    is $count, $n, "$n bodies found";
    if ($opt4) {
        ok $RE{net}{IPv4}->matches($rtn), "Found an IPv4 address"
            or diag "No IPv4 address in:\n$rtn\n";
    } else {
        ok !$RE{net}{IPv4}->matches($rtn), "No IPv4 address expected or found"
            or diag "Found an IPv4 address:\n$rtn\n";
    }
    if ($opt6) {
        ok $RE{net}{IPv6}->matches($rtn), "Found an IPv6 address"
            or diag "No IPv6 address in:\n$rtn\n";
    } else {
        ok !$RE{net}{IPv6}->matches($rtn), "No IPv6 address expected or found"
            or diag "Found an IPv6 address:\n$rtn\n";
    }
}
