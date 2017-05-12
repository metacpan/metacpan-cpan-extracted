#!/usr/local/bin/perl -w

# Tests of object-level fetches and following
######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
use constant PORT => $ENV{ACEDB_PORT} || 2007;

BEGIN {$| = 1; print "1..17\n"; }
END {print "not ok 1\n" unless $loaded;}
use Ace;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

# Test code:
my ($db,$obj);
test(2,$db = Ace->connect(-host=>HOST,-port=>PORT,-timeout=>50),
     "couldn't establish connection");
die "Couldn't establish connection to database.  Aborting tests.\n" unless $db;
test(3,$me = Ace::Object->new('Author','Dent AD',$db),"couldn't create new object");
test(4,$me->add('Also_known_as','Arthur D. Dent'));
test(5,$me->add('Laboratory','FF'));
test(6,$me->add('Address.Mail','Heart of Gold'));
test(7,$me->add('Address.Mail','Western End'));
test(8,$me->add('Address.Mail','Unfashionable Outer Rim of the Milky Way'));
test(9,$me->add('Address.Fax','1111111'));
test(10,$me->replace('Address.Fax','1111111','2222222'));
test(11,$me->add('Address.Phone','123456'));
test(12,$me->delete('Address.Phone'));
# Either the commit should succeed, or it should fail with a Write Access denied failure
test(13,$me->commit || $me->error eq 'Write access denied',"commit failure:\n $Ace::Error"); 
test(14,$me->kill   || $me->error eq 'Write access denied',"kill failure:\n $Ace::Error"); 
# Now we're going to test whether parse errors are correctly reported
test(15,$me = Ace::Object->new('Author','Dent AD',$db),"couldn't create new object");
test(16,$me->add('Address.VideoPhone','123456'));
test(17,!$me->commit,"failed to catch parse error");
$me->kill;
