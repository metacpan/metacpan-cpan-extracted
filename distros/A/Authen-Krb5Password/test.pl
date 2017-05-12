# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Authen::Krb5Password;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# There's little specific test code because practical testing would require
# creation of a test user principal and password, along with a test service
# principal and keytab file.

print kpass('foo', 'bar', 'baz', 'fink') ? "not ok 2\n" : "ok 2\n";
