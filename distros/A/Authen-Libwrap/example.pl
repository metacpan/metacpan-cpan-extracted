use Authen::Libwrap qw( hosts_ctl STRING_UNKNOWN );

$rc = hosts_ctl( "james", "localhost", "127.0.0.1", STRING_UNKNOWN );
print "Access is ", $rc ? "granted" : "refused", "\n";

$rc = hosts_ctl( "james", "expn.ehlo.com", "10.1.1.2", STRING_UNKNOWN );
print "Access is ", $rc ? "granted" : "refused", "\n";

$Authen::Libwrap::DEBUG = 1;
$rc = hosts_ctl( "james", "vrfy.ehlo.com", "10.1.1.1", "STRING_UNKNOWN" );
print "Access is ", $rc ? "granted" : "refused", "\n";
