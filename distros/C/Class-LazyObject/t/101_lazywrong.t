#!/usr/bin/perl -w
use strict;

# Test an incorrect lazy object.

use FindBin;

use lib $FindBin::Bin . '/testmodules';

use TestCode::PlainObject;
use Test::More tests => 1;
use Test::Exception;

package Simple::Lazy::Incorrect;
#A lazy object without enough parameters passed to inherit.

use strict;
use warnings;
use Class::LazyObject;
use Simple;
use Test::More;
use Test::Exception;

use vars '@ISA';
@ISA = 'Class::LazyObject';

throws_ok
{
	Class::LazyObject->inherit(
		deflated_class => __PACKAGE__,
		);
} "/You did not pass 'inflated_class', which is a required parameter/", 'Complains about missing parameters passed to inherit';



1;