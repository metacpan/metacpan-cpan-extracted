#!/opt/bin/perl -w

# Tests of object-level fetches and following
######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
use constant PORT => $ENV{ACEDB_PORT} || 2007;

BEGIN {$| = 1; print "1..36\n"; }
END {print "not ok 1\n" unless $loaded;}
use Ace;
use constant TEST_CACHE=>0;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

# Test code:
my ($db,$obj,@obj,$lab);
my $DATA = q{Address  Mail    The Sanger Centre
                 Hinxton Hall
                 Hinxton
                 Cambridge CB10 1SA
                 U.K.
         E_mail  jes@sanger.ac.uk
         Phone   1223-834244
                 1223-494958
         Fax     1223-494919
};
my @args  = (-host=>HOST,-port=>PORT,-timeout=>50);
push @args,(-cache=>{}
	   ) if TEST_CACHE || $ENV{TEST_CACHE};
Ace->debug(0);
test(2,$db = Ace->connect(@args),"connection failure");
die "Couldn't establish connection to database.  Aborting tests.\n" unless $db;
test(3,$obj = $db->fetch('Author','Sulston JE'),"fetch failure");
print STDERR "\n  ...Failed to get test object. Wrong database?\n     Expect more failures... " 
  unless $obj;
test(4,defined($obj) && $obj eq 'Sulston JE',"string overload failure");
test(5,@obj = $db->fetch('Author','Sulston*'),"wildcard failure");
test(6,@obj==2,"failed to recover two authors from Sulston*");
test(7,defined($obj) && $obj->right eq 'Also_known_as',"auto fill failure");
test(8,defined($obj) && $obj->Also_known_as eq 'John Sulston',"automatic method generation failure");
test(9,defined($obj) && $obj->Also_known_as->pick eq 'John Sulston',"pick failure");
test(10,defined($obj) && (@obj = $obj->Address(2)) == 9,"col failure");
test(11,defined($obj) && ($lab = $obj->Laboratory),"fetch failure");
test(12,defined($lab) && join(' ',sort($lab->tags)) =~ /^Address CGC Staff$/,"tags failure");
test(13,defined($lab) && $lab->at('CGC.Allele_designation')->at eq 'e',"compound path failure");
test(14,defined($obj) && $obj->Address(0)->asString eq $DATA,"asString() method");
test(15,$db->ping,"can't ping");
test(16,$db->classes,"can't count classes");
test(17,defined($obj) && join(' ',sort $obj->fetch('Laboratory')->tags) =~ /^Address CGC Staff/,"fetch failure");
test(18,defined($obj) && join(' ',$obj->Address(0)->row) eq "Address Mail The Sanger Centre","row() failure");
test(19,defined($obj) && join(' ',$obj->Address(0)->row(1)) eq "Mail The Sanger Centre","row() failure");
test(20,defined($obj) && (@h=$obj->Address(2)),"tag[2] failure");
test(21,defined($obj) && (@h==9),"tag[2] failure");
test(22,$iterator1 = $db->fetch_many('Author','S*'),"fetch_many() failure (1)");
test(23,$iterator2 = $db->fetch_many('Clone','*'),"fetch_many() failure (2)");
test(24,$obj1 = $iterator1->next,"iterator failure (1)");
test(25,!$obj1->filled,"got filled object, expected unfilled");
test(26,($obj2 = $iterator1->next) && $obj1 ne $obj2,"iterator failure (2)");
test(27,($obj3 = $iterator2->next) && $obj3->class eq 'Clone',"iterator failure (3)");
test(28,($obj4 = $iterator1->next) && $obj4->class eq 'Author',"iterator failure (4)");
test(29,$iterator1 = $db->fetch_many(-class=>'Author',-name=>'S*',-filled=>1),"fetch_many(filled) failure");
test(30,($obj1 = $iterator1->next) && $obj1 && $obj1->filled,"expected filled object, got unfilled or null");
# test scalar/array contexts
$obj = $db->fetch('Author','S*');
test(31,$obj=~/^\d+$/,"did not get object count in scalar context with wildcard");
$obj = $db->fetch('Author','Sulston JE');
test(32,$obj eq 'Sulston JE',"did not get object in scalar context without wildcard");
@obj = $db->fetch('Author','Su*');
test(33,@obj>1,"did not get list of objects in array context with wildcard");
@papers = $obj->follow('Paper');
test(34,@papers>1,"did not get list of papers from follow()");
test(35,@papers && $papers[0]->Title,"did not get title from first paper");
@papers_new = $db->find(-query=>qq{Author IS "Sulston JE" ; >Paper});
test(36,@papers == @papers_new,"find() did not find right number of papers")
