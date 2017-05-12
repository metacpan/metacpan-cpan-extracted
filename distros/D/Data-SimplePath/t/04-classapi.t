#!/usr/bin/perl -T

use strict;
use warnings;

use Data::SimplePath;

BEGIN {
	use Test::More;
}

BEGIN {
	eval 'use Test::ClassAPI';
	plan ('skip_all' => 'Test::ClassAPI required for testing the API') if $@;
}

Test::ClassAPI -> execute ('complete');

__DATA__

# note that we will only check the documented public functions plus import:

Data::SimplePath=class

[Data::SimplePath]
auto_array=method
clone=method
data=method
does_exist=method
get=method
import=method
key=method
new=method
normalize_key=method
path=method
remove=method
replace_leaf=method
separator=method
set=method
