# This is a valid class, not declared using Class::Generate.
# It cannot however be a superclass of something declared
# through that package, because it is based on a reference
# to a scalar, not to an array or hash.
package A_Class;
use strict;

my $instances_declared = 0;
sub init() {
    $instances_declared = 0;
}

sub new {
    my $class = shift;
    my $v = ++$instances_declared;
    return bless \$v, $class;
}

sub value {
    my $self = shift;
    return $$self;
}

1;
