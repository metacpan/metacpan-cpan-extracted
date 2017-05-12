use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 3;
}
use Data::Stag;
use strict;

eval {
    require "XML/Parser/PerlSAX.pm";
};
if ($@) {
    for (1..3) {
        skip("XML::Parser::PerlSAX not installed",1);
    }
    exit 0;
}


my $xml =<<EOM
 <dataset>
   <person>
     <name>jim</name>
   </person>
 </dataset>
EOM
  ;

my $s = Data::Stag->from('xmlstr', $xml);
my ($person) = $s->qmatch('person', name=>'jim');
$person->add('phone_no', '555-1111', '555-2222');
print $person->sxpr;
$person->add_phone_no('555-3333','555-4444');
print $person->sxpr;

$s->add(person=>[[name=>"fred"],
                  [phone_no=>"555-5555"]]);
print $s->sxpr;
$s->add_person([[name=>"fred"],
                [phone_no=>"555-5555"]]);
print $s->sxpr;
$s->unset('person');
$s->addchild($person);
my $attnode = Data::Stag->new('@'=>[[id=>5]]);
$person->addchild($attnode);
print $s->xml;
$attnode->addchild([foo=>6]);
print $s->xml;
ok($s->get('person/@/id'), 5);
ok($s->get('person/@/foo'), 6);
ok($s->get('person/name'), 'jim');
