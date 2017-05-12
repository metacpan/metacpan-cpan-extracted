#!/usr/bin/perl

BEGIN{push @INC, "./../blib/lib/"}

use Biblio::ILL::ISO::Request;

my $debug = 1;

my $msg = new Biblio::ILL::ISO::Request;

my $href = $msg->read("msg_01.request.ber", $debug);
#my $href = $msg->read("sfu.ber", $debug);

print "\n===[ From the read ]=================================\n\n";
print $msg->debug($href);

print "\n===[ From the 'from_asn processing ]=================\n\n";
$msg = $msg->from_asn($href);

print "\n===[ As pretty string ]==============================\n\n";
print $msg->as_pretty_string();

