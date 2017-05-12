#!/usr/bin/perl -T

use strict;
use warnings;

BEGIN {
	use Test::More;
	use Test::NoWarnings;
	use Test::Warn;
	plan ('tests' => 5);
}

my $warning = qr/^Unknown option: /;

# unknown options must cause a warning:
warning_like
	{
		require Data::SimplePath;
		Data::SimplePath -> import ('INVALID' => 'OPTION');
	}
	$warning, 'Invalid option';

# undef is not allowed and must be ignored:
Data::SimplePath -> import ('SEPARATOR' => undef);

# check if the private method _global returns the correct default values (there is no other way to
# access the config variables):
is ( Data::SimplePath::_global ('AUTO_ARRAY'  ),   1, 'AUTO_ARRAY set to 1'   );
is ( Data::SimplePath::_global ('REPLACE_LEAF'),   1, 'REPLACE_LEAF set to 1' );
is ( Data::SimplePath::_global ('SEPARATOR'   ), '/', 'SEPARATOR set to /'    );
