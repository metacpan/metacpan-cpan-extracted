package Simple::Lazy;
#A lazy object that inflates to simple.

use strict;
use warnings;
use Class::LazyObject;
use Simple;

use vars '@ISA';
@ISA = 'Class::LazyObject';

Class::LazyObject->inherit(
	deflated_class => __PACKAGE__,
	inflated_class => 'Simple',
	);


1;
			