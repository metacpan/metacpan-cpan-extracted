package t::Object::Hash;
use strict;

use Class::InsideOut qw( public register );

public name => my %name; 
public weight => my %weight;

sub new { register( bless {}, shift ) }

1;
