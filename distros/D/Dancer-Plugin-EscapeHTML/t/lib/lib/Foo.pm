package Foo;

use strict;

sub new {
    return bless { foo => '<p>In an object</p>' } => shift;
}
sub bar { shift->{foo} }
1;

