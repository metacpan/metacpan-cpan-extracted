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
use strict;

my $s = Data::Stag->unflatten(people=>[
				       person=>{name=>'Sherlock Holmes',
						job=>'detective'},
				       person=>{name=>'James Bond',
						job=>'secret agent'},
				      ],
			     );
print $s->xml;
my $orig = $s->d;


my $person;
my $address = Data::Stag->unflatten(address=>{
					      address_line=>"221B Baker Street",
					      city=>"London",
					      country=>"Great Britain",
					     });
($person) = $s->qmatch('person', (name => "Sherlock Holmes"));
$person->set("address", $address->data);
print $s->xml;
($person) = $s->qmatch('person', (job=>'detective'));

ok([$s->qmatch('person', (job=>'detective'))]->[0]->sget_address->get_city eq 'London');

$s = $orig;
($person) = $s->qmatch('person', (name => "Sherlock Holmes"));
#$person->set("address", $address->data);
$person->set(@$address);
print $s->xml;
ok([$s->qmatch('person', (job=>'detective'))]->[0]->sget_address->get_city eq 'London');

