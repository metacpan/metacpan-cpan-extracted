#!/usr/bin/perl

BEGIN{push @INC, "./../blib/lib/"}

use Biblio::ILL::ISO::StatusQuery;

my $msg = new Biblio::ILL::ISO::StatusQuery;

my $href = $msg->read("msg_18.status-query.ber",1);

#print "\n===[ From the read ]=================================\n\n";
#print $msg->debug($href);

print "\n===[ From the 'from_asn processing ]=================\n\n";
$msg = $msg->from_asn($href);

print "\n===[ As pretty string ]==============================\n\n";
print $msg->as_pretty_string();

