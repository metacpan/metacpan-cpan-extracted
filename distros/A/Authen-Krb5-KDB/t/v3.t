# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..48\n"; }
END {print "not ok 1\n" unless $loaded;}
use Authen::Krb5::KDB;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# if we are not loaded from something else, set checks to 1
$checks ||= 1;
my $db = Authen::Krb5::KDB->new( file  => 't/slave_datatrans.b6',
				 save => 1, checks => $checks );
print "not " unless (ref($db) eq "Authen::Krb5::KDB");
print "ok 2\n";

my $Nprincs   = 0;
my $Npolicies = 0;

while (my $p = $db->next) {
    if ($p->type eq 'princ') {
	$Nprincs++;
    }
    if ($p->type eq 'policy') {
	$Npolicies++;
    }
}
print "not " unless ($Nprincs   == 9);
print "ok 3\n";
print "not " unless ($Npolicies == 0);
print "ok 4\n";

print "not " unless ($db->close);
print "ok 5\n";

require "t/princ-check.pl";
check_principals($db->principals, 2); # second are is number of TLs to expect

my $pol = $db->policies;
print "not " unless (ref($pol) eq "ARRAY");
print "ok 47\n";
print "not " unless (scalar @{$pol} == 0);
print "ok 48\n";

1;
