use Class::Prototyped qw(:EZACCESS);
use Class::Prototyped::Graph;

package A;

sub aa { }

package main;

my $p1 = Class::Prototyped->new( name => 'p1', '*' => 'A' );
my $p2 = Class::Prototyped->new( name => 'p2', '*' => $p1 );
my $p3 = Class::Prototyped->new( name => 'p3', '*' => $p2, '*' => $p1, '*' => 'A' );
my $p4 = Class::Prototyped->new( name => 'p4', '*' => $p3, '*' => $p1 );

Class::Prototyped::Mirror::graph( 'name', $p4 );
print "output is in graph.png";
