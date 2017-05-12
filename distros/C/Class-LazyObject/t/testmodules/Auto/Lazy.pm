package Auto::Lazy;
#A lazy object that inflates to auto.

use strict;
use warnings;
use Class::LazyObject;
use Auto;

use vars '@ISA';
@ISA = 'Class::LazyObject';

Class::LazyObject->inherit(
	deflated_class => __PACKAGE__,
	inflated_class => 'Auto',
	);


1;
			