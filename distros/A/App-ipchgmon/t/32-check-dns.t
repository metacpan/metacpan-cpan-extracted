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

# Exercises the "check_dns" sub. This takes a dns name and an aoaref
# and checks whether the ip address of the dns name is correct per
# the aoaref. It should fire off emails if there is a difference, so
# Email::Stuffer's send routine is mocked to extract data from the
# object created by the new() method. With both ipv4 and ipv6 options
# set, this should result in 2 emails.

my $rtn = ''; # Used to capture the contents of the object

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
$App::ipchgmon::opt_4 = 1;
$App::ipchgmon::opt_6 = 1;

# Build the aoaref
my $csv = Text::CSV->new();
my ($aoaref, @fields);
$csv->combine("11.11.11.11");
push @fields, $csv->string();
$csv->combine("2022-08-28T00:00:00Z");
push @fields, $csv->string();
push @$aoaref, [@fields];
undef @fields;
$csv->combine("101.101.101.101");
push @fields, $csv->string();
$csv->combine("2022-08-28T01:01:01Z");
push @fields, $csv->string();
push @$aoaref, [@fields];
undef @fields;
$csv->combine("B::0");
push @fields, $csv->string();
$csv->combine("2022-08-28T00:00:00Z");
push @fields, $csv->string();
push @$aoaref, [@fields];
undef @fields;
$csv->combine("B::1");
push @fields, $csv->string();
$csv->combine("2022-08-28T01:01:01Z");
push @fields, $csv->string();
push @$aoaref, [@fields];

# Run the tests in a simple case
my $dnsname = 'example.com';
App::ipchgmon::check_dns($dnsname, $aoaref);
test_email_sent();

## No leeway, so an immediate recheck should re-send.
undef $aoaref;
my ($ip4, $ip6) = App::ipchgmon::nslookup('example.com');
my $dt = DateTime->now;
my $timestamp = $dt->rfc3339;
$csv->combine($timestamp);
my $ts_elt = $csv->string();
for my $ip ($ip4, $ip6) {
    $csv->combine($ip);
    push @$aoaref, [$csv->string(), $ts_elt];
}
sleep 2; # Make sure timestamp changes
$rtn = '';
App::ipchgmon::check_dns($dnsname, $aoaref);
test_email_sent();

## Check there are no emails if within leeway
$rtn = '';
$App::ipchgmon::opt_leeway = 86400;
App::ipchgmon::check_dns($dnsname, $aoaref);
is $rtn, '', 'No emails populated if within leeway';

done_testing();

sub test_email_sent {
    like $rtn, qr(To: dnsto\@example.com), '"To" rendered correctly';
    like $rtn, qr(From: dnsfrom\@example.com), '"From" rendered correctly';
    like $rtn, qr(Subject: DNS test), '"Subject" rendered correctly';
    like $rtn, qr(example\.com has moved to), 'Body rendered correctly';
    my $count =()= ($rtn =~ m/dnsto\@example\.com/gms);
    is $count, 2, '2 destination addresses found';
    $count =()= ($rtn =~ m/From: dnsfrom\@example\.com/gms);
    is $count, 2, '2 source addresses found';
    $count =()= ($rtn =~ m/Subject: DNS test/gms);
    is $count, 2, '2 subjects found';
    $count =()= ($rtn =~ m/example\.com has moved to/gms);
    is $count, 2, '2 bodies found';
    ok $RE{net}{IPv4}->matches($rtn), "Found an IPv4 address"
        or diag "No IPv4 address in:\n$rtn\n";
    ok $RE{net}{IPv6}->matches($rtn), "Found an IPv6 address"
        or diag "No IPv6 address in:\n$rtn\n";
}
