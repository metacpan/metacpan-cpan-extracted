package JustNew::Lazy;
#A lazy object that inflates to JustNew.

use strict;
use warnings;
use Class::LazyObject;
use JustNew;

use vars '@ISA';
@ISA = 'Class::LazyObject';

Class::LazyObject->inherit(
	deflated_class => __PACKAGE__,
	inflated_class => 'JustNew',
	inflate => sub {
		my ($class, $id) = @_;
		return $class->new($id);
		}
	);


1;
			