package t::Object::Array;
use strict;

use Class::InsideOut qw( public register );

public name => my %name; 
public height => my %height;

sub new { register( bless [], shift ) }

1;
