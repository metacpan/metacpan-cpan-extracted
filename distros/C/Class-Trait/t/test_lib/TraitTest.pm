
package TraitTest;

use strict;
use warnings;

use base qw(TraitTestBase);    

use Class::Trait (
    TCompositeTest => { 
        alias   => { stringValue => "strVal" },
        exclude => [ "stringValue" ]
    },
    "TPrintable"
    );
    

sub compare {
   my ($self, $right) = @_;
   return ($self->{value} <=> $right->{value});
}

sub toString {
	my ($self) = @_;
	return sprintf("%.3f", $self->SUPER::toString()) . " (overridden stringification)";
}

sub compositeTestRequirement { return "Composite Test Requirement" }

1;

__DATA__
