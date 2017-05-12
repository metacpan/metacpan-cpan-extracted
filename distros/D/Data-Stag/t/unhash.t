use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 4;
}
use Data::Stag;
use strict;

my $s = Data::Stag->unhash(
			   Jim => { First_name => 'James',
                                         Last_name  => 'Hill',
                                         Age        => 34,
                                         Address    => {
                                                Street => ['The Manse',
                                                           '19 Chestnut Ln'],
                                                City  => 'Garden City',
                                                State => 'NY',
                                                Zip   => 11291 }
                                       },
			   Sally => { First_name => 'Sarah',
				      Last_name  => 'James',
				      Age        => 30,
				      Address    => {
						     Street => 'Hickory Street',
						     City  => 'Katonah',
						     State => 'NY',
						     Zip  => 10578 }
				    }
			  );

print $s->xml;
my %h = $s->hash;
#use Data::Dumper;
#print Dumper \%h;
my $s2 = Data::Stag->unhash(%h);
print $s2->xml;
my @street = $s2->find("Jim/Address/Street");
print "@street\n";
ok("@street" eq "The Manse 19 Chestnut Ln"); 
$s = Data::Stag->unhash(
			Name=>'Fred',
			Friend=>['Jill',
				 'John',
				 'Gerald'
				],
			    Attributes => { Hair => 'blonde',
					    Eyes => 'blue' }
		       );
print $s->xml;

%h = $s->hash;
#use Data::Dumper;
#print Dumper \%h;
$s = Data::Stag->unhash(%h);
print $s->xml;
my @friends = $s->get_Friend;
print "@friends\n";
ok(@friends == 3);
ok($s->get("Attributes/Hair") eq 'blonde');
ok($s->get("Attributes/Eyes") eq 'blue');
