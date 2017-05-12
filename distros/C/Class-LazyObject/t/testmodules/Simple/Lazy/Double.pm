package Simple::Lazy::Double;
#A lazy object inside a lazy object

use strict;
use warnings;
use Class::LazyObject;
use Simple::Lazy;

use vars '@ISA';
@ISA = 'Class::LazyObject';

Class::LazyObject->inherit(
	deflated_class => __PACKAGE__,
	inflated_class => 'Simple::Lazy',
	inflate => sub #we need to define this because Class::LazyObject's constructor is new();
		{
			my ($class, $id) = @_;
			return $class->new($id);
		}
	);


1;
			