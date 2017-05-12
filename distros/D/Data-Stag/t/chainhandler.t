use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 2;
}
use Data::Stag;
use FileHandle;

my $fn = "t/data/persons.el";
my %catch =
  (
    person => sub {
	my ($self, $person) = @_;
	$person->set_fullname($person->get_firstname . ' ' .
			      $person->get_lastname);
	$person;
    },
    address => sub {
	my ($self, $address) = @_;
	# remove addresses altogether from processed file
#	$address->free;
	return;
    },
  );

my $ih = Data::Stag->makehandler(
				 %catch
				);
#Data::Stag->parse(-file=>$fn, -handler=>$ih);
#print $ih->stag->sxpr;
#$ih->stag->free;

print "chainhandler...\n";
my $fh = FileHandle->new(">t/data/person-processed.el") || die;
my $w = Data::Stag->getformathandler('sxpr');
$w->fh($fh);
my $ch = Data::Stag->chainhandlers(
#				   [keys %catch],
				   ['person', 'address'],
				   $ih,
				   $w,
				  );


Data::Stag->parse(-file=>$fn, -handler=>$ch);
$w->fh->close;
print "checking..\n";
my $pp = Data::Stag->parse("t/data/person-processed.el");
my @full = $pp->find("fullname");
ok("@full" eq "joe bloggs clark kent");
my @address = $pp->find("address");
ok(!@address);

