#!/usr/local/bin/perl
#
# simple.pl
# Example of how to use Authen::ACE4 for simple 
# authentication
use Authen::ACE4;

my $username = 'mikem';

Authen::ACE4::AceInitialize();

print "Enter Username:\n";
$username = <>;
chomp $username;

($result, $handle, $moreData, $echoFlag, $respTimeout, $nextRespLen, $prompt) = Authen::ACE4::AceStartAuth($username);

die "AceStartAuth failed: $prompt\n"
    unless $result == Authen::ACE4::ACM_OK;

while ($moreData)
{
    print "$prompt\n";
    $resp = <>;
    chomp $resp;

    ($result, $moreData, $echoFlag, $respTimeout, $nextRespLen, $prompt) = Authen::ACE4::AceContinueAuth($handle, $resp);

    die "AceContinueAuth failed: $prompt\n"
	unless $result == Authen::ACE4::ACM_OK;

}

print "$prompt\n";
($result, $status) = Authen::ACE4::AceGetAuthenticationStatus($handle);
# If $result is ACE_SUCCESS, then $status is defined, and 
# indicates ACM_OK, ACM_ACCESS_DENIED etc
$result = Authen::ACE4::AceCloseAuth($handle);

exit $status;




