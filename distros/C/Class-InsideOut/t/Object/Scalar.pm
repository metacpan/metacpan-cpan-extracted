package t::Object::Scalar;
#@ISA = qw( Bogus::Superclass );

use strict;

use Class::InsideOut qw( public register );

public name => my %name; 
public age => my %age;

sub new { register( bless \(my $s), shift) }

1;
