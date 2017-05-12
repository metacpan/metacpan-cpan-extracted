# test.pl
# Test program for Authen::ACE4
#
# Interface to Securid ACE/Server client API version 4
# Copyright (C) 2001 Open System Consultants
# Author: Mike McCauley mikem@open.com.au
# $Id: test.pl,v 1.1 2001/07/28 02:40:47 mikem Exp $

END {print "not ok 1\n" unless $loaded;}

use Authen::ACE4 qw(ACM_OK ACE_SUCCESS);

$loaded = 1;
$testno = 1;
printok($testno++, 1, 'failed to load');

# If you see an error message like:
# /var/ace/sdconf.rec: No such file or directory
# on Unix, you may have a non-stanrard path to
# your sdconf.rec. Ttry setting the VAR_ACE environment variable
# to the correct path to your data directory
Authen::ACE4::AceInitialize();
printok($testno++, 1, 'failed to initialize');

print "enter a SecurID username to test with:\n";
$username = <>;
chomp $username;

($result, $handle, $moreData, $echoFlag, $respTimeout, 
$nextRespLen, $prompt) 
    = Authen::ACE4::AceStartAuth($username);
printok($testno++, $result == ACM_OK, "AceStartAuth failed: $prompt");

while ($moreData)
{
    print "$prompt\n";
    $resp = <>;
    chomp $resp;

    ($result, $moreData, $echoFlag, $respTimeout, 
     $nextRespLen, $prompt) 
	= Authen::ACE4::AceContinueAuth($handle, $resp);
    
    printok($testno++, $result == ACM_OK, "AceContinueAuth failed: $prompt");
}

($result, $status) = Authen::ACE4::AceGetAuthenticationStatus($handle);
# If $result is ACE_SUCCESS, then $status is defined, and 
# indicates ACM_OK, ACM_ACCESS_DENIED etc
printok($testno++, $result == ACE_SUCCESS, 'AceGetAuthenticationStatus failed');

printok($testno++, $result == ACE_SUCCESS && $status == ACM_OK, "Authentication failed: $prompt");

($result, $shell) = Authen::ACE4::AceGetShell($handle);
printok($testno++, $result == ACE_SUCCESS, 'AceGetShell failed');


# These wont yield useful data, but test the calls anyway
($result, $alpha) = Authen::ACE4::AceGetAlphanumeric($handle);
printok($testno++, $result == ACE_SUCCESS, 'AceGetAlphanumeric failed');

($result, $maxpin) = Authen::ACE4::AceGetMaxPinLen($handle);
printok($testno++, $result == ACE_SUCCESS, 'AceGetMaxPinLen failed');

($result, $minpin) = Authen::ACE4::AceGetMinPinLen($handle);
printok($testno++, $result == ACE_SUCCESS, 'AceGetMinPinLen failed');

($result, $pin) = Authen::ACE4::AceGetSystemPin($handle);
printok($testno++, $result == ACE_SUCCESS, 'AceGetSystemPin failed');

($result, $usersel) = Authen::ACE4::AceGetUserSelectable($handle);
printok($testno++, $result == ACE_SUCCESS, 'AceGetUserSelectable failed');

$result = Authen::ACE4::AceCloseAuth($handle);
printok($testno++, $result == ACM_OK, 'AceCloseAuth failed');

sub printok 
{
    my ($n, $ok, $message) = @_;
    print($ok? "ok $n\n" : "not ok $n ($message)\n");
    $npass++ if $ok;
}
