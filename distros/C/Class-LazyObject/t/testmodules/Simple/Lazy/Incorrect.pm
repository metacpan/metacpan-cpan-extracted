package Simple::Lazy::Incorrect;
#A lazy object without enough parameters passed to inherit.

use strict;
use warnings;
use Class::LazyObject;
use Simple;

use vars '@ISA';
@ISA = 'Class::LazyObject';

Class::LazyObject->inherit(
	deflated_class => __PACKAGE__,
	);


1;
			