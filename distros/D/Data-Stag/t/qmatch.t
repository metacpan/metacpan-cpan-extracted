use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 9;
}
use Data::Stag;
use strict;

my $s = Data::Stag->unflatten(people=>[
				       person=>{
						name=>'big dave',
						address=>{
							  street=>'foo',
							  city=>'methyl',
							 },
					       },
				       person=>{
						name=>'shuggy',
						address=>{
							  street=>'bar',
							  city=>'auchtermuchty',
							 },
					       },
				       ],
			     );
print $s->xml;

my @persons;
@persons = $s->qmatch('person', (name=>'shuggy'));
ok(@persons == 1);
ok($persons[0]->get('address/city') eq 'auchtermuchty');

@persons = $s->qmatch('person', ('address/street'=>'foo'));
ok(@persons == 1);
ok($persons[0]->get_name eq 'big dave');

# should not find anything, because street is not a direct subnode of person
@persons = $s->qmatch('person', (street=>'foo'));
ok(@persons==0);
print $_->xml foreach @persons;

my @addresses = $s->qmatch('address', (city=>'auchtermuchty'));
ok (@addresses == 1);


$s = Data::Stag->unflatten(c=>{
			       id=>1,
			       c=>{
				   id=>2
				  }
			      });

my @cs = $s->findnode('c');
print $_->xml foreach @cs;
ok(@cs==2);

#print $s->xml;
my @x = $s->qmatch('c', 'id', 2);
print "\n\n";
ok(@x==1);
print $_->xml foreach @x;

@x = $s->qmatch('c', 'id', 1);
print "\n\n";
ok(@x==1);
print $_->xml foreach @x;

