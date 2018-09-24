
use strict;
use warnings;

package Context::Singleton::Exception::Deduced;

our $VERSION = v1.0.5;

use Exception::Class ( __PACKAGE__ );

sub new {
	my ($self, $rule) = @_;

	$self->SUPER::new (error => "Already deduced: $rule");
}

1;

