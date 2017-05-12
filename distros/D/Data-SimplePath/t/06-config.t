#!/usr/bin/perl -T

use strict;
use warnings;

use Data::SimplePath;

BEGIN {
	use Test::More;
	use Test::NoWarnings;
	plan ('tests' => 105);
}

# new object with some data (unimportant) and default configuration:
my $h = Data::SimplePath -> new ({'a' => 'b', 'c' => 'd'});

# check that getting the config option does not change it [2 * 3 tests]:
for (1 .. 2) {
	is ( $h -> auto_array   (),   1, "AUTO_ARRAY is 1 ($_)"   );
	is ( $h -> replace_leaf (),   1, "REPLACE_LEAF is 1 ($_)" );
	is ( $h -> separator    (), '/', "SEPARATOR is / ($_)"    );
}

# data must never be changed by setting config stuff:
is_deeply (scalar $h -> data (), {'a' => 'b', 'c' => 'd'}, 'Data ok');

# change the config options, check that return value are the old values. first test with undef
# param must not change the option! [9 tests]
is ( $h -> auto_array   (undef),   1, 'AUTO_ARRAY is 1'    );
is ( $h -> auto_array   (    0),   1, 'AUTO_ARRAY was 1'   );
is ( $h -> auto_array   (    1),   0, 'AUTO_ARRAY was 0'   );
is ( $h -> replace_leaf (undef),   1, 'REPLACE_LEAF is 1'  );
is ( $h -> replace_leaf (    0),   1, 'REPLACE_LEAF was 1' );
is ( $h -> replace_leaf (    1),   0, 'REPLACE_LEAF was 0' );
is ( $h -> separator    (undef), '/', 'SEPARATOR is /'     );
is ( $h -> separator    (  '#'), '/', 'SEPARATOR was /'    );
is ( $h -> separator    (  '/'), '#', 'SEPARATOR was #'    );

is_deeply (scalar $h -> data (), {'a' => 'b', 'c' => 'd'}, 'Data ok');

# repeat the tests directly using the _config method:

for (1 .. 2) {
	is ( $h -> _config ('AUTO_ARRAY'  ),   1, "AUTO_ARRAY is 1 ($_)"   );
	is ( $h -> _config ('REPLACE_LEAF'),   1, "REPLACE_LEAF is 1 ($_)" );
	is ( $h -> _config ('SEPARATOR'   ), '/', "SEPARATOR is / ($_)"    );
}

is_deeply (scalar $h -> data (), {'a' => 'b', 'c' => 'd'}, 'Data ok');

is ( $h -> _config ('AUTO_ARRAY',   undef),   1, 'AUTO_ARRAY is 1'    );
is ( $h -> _config ('AUTO_ARRAY',       0),   1, 'AUTO_ARRAY ass 1'   );
is ( $h -> _config ('AUTO_ARRAY',       1),   0, 'AUTO_ARRAY was 0'   );
is ( $h -> _config ('REPLACE_LEAF', undef),   1, 'REPLACE_LEAF is 1'  );
is ( $h -> _config ('REPLACE_LEAF',     0),   1, 'REPLACE_LEAF was 1' );
is ( $h -> _config ('REPLACE_LEAF',     1),   0, 'REPLACE_LEAF was 0' );
is ( $h -> _config ('SEPARATOR',    undef), '/', 'SEPARATOR is /'     );
is ( $h -> _config ('SEPARATOR',      ':'), '/', 'SEPARATOR was /'    );
is ( $h -> _config ('SEPARATOR',      '/'), ':', 'SEPARATOR was :'    );

is_deeply (scalar $h -> data (), {'a' => 'b', 'c' => 'd'}, 'Data ok');

# DATA must not be changed by _config:
is ( $h -> _config ('DATA'), undef, 'DATA is undef' );
foreach (undef, 'a', {}, [], qr/.*/, sub {}) {
	is ( $h -> _config ('DATA', $_), undef, "DATA is undef" );
}

is_deeply (scalar $h -> data (), {'a' => 'b', 'c' => 'd'}, 'Data ok');

# and invalid keys must always return undef:
foreach my $option ('INVALID', qr/.*/, sub {}, [], {}, \('AUTO_ARRAY')) {
	is ( $h -> _config ($option), undef, 'Invalid option is undef' );
	foreach (undef, 'a', {}, [], qr/.*/, sub {}) {
		is ( $h -> _config ($option, $_), undef, "Invalid option is undef" );
	}
}

is_deeply (scalar $h -> data (), {'a' => 'b', 'c' => 'd'}, 'Data ok');

# _global is used to set and/or get global config values, ie. settings changed on import (see
# t/02 and t/03). we perform some additional checks here, seems to fit well in this file...

# check default values:
is ( Data::SimplePath::_global ('AUTO_ARRAY'  ),   1, 'AUTO_ARRAY default'   );
is ( Data::SimplePath::_global ('REPLACE_LEAF'),   1, 'REPLACE_LEAF default' );
is ( Data::SimplePath::_global ('SEPARATOR'   ), '/', 'SEPARATOR default'    );

# undef must not change the values:
is ( Data::SimplePath::_global ('AUTO_ARRAY',   undef),   1, 'AUTO_ARRAY undef'   );
is ( Data::SimplePath::_global ('REPLACE_LEAF', undef),   1, 'REPLACE_LEAF undef' );
is ( Data::SimplePath::_global ('SEPARATOR',    undef), '/', 'SEPARATOR undef'    );

# check again:
is ( Data::SimplePath::_global ('AUTO_ARRAY'  ),   1, 'AUTO_ARRAY still default'   );
is ( Data::SimplePath::_global ('REPLACE_LEAF'),   1, 'REPLACE_LEAF still default' );
is ( Data::SimplePath::_global ('SEPARATOR'   ), '/', 'SEPARATOR still default'    );

# set some other values, must return true:
ok ( Data::SimplePath::_global ('AUTO_ARRAY',     0), 'AUTO_ARRAY changed'   );
ok ( Data::SimplePath::_global ('REPLACE_LEAF',   0), 'REPLACE_LEAF changed' );
ok ( Data::SimplePath::_global ('SEPARATOR',    '#'), 'SEPARATOR changed'    );

# check again:
is ( Data::SimplePath::_global ('AUTO_ARRAY'  ),   0, 'AUTO_ARRAY checked'   );
is ( Data::SimplePath::_global ('REPLACE_LEAF'),   0, 'REPLACE_LEAF checked' );
is ( Data::SimplePath::_global ('SEPARATOR'   ), '#', 'SEPARATOR checked'    );

# invalid config option:
is ( Data::SimplePath::_global ('INVALID'   ), undef, 'INVALID undef'       );
is ( Data::SimplePath::_global ('INVALID', 1), undef, 'INVALID set'         );
is ( Data::SimplePath::_global ('INVALID'   ), undef, 'INVALID still undef' );

is_deeply (scalar $h -> data (), {'a' => 'b', 'c' => 'd'}, 'Data ok');

# note: changing config values when creating the object is tested in t/05-new.t
