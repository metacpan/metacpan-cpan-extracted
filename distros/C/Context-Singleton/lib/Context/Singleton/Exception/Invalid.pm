
use strict;
use warnings;

package Context::Singleton::Exception::Invalid;

our $VERSION = v1.0.4;

use Exception::Class ( __PACKAGE__ );

sub new {
	my ($self, @params) = @_;

	$self->SUPER::new (error => 'Invalid value', @params);
}

1;

