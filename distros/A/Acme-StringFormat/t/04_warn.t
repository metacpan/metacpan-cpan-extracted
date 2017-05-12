#!perl

use strict;
use warnings;

use Test::More;

BEGIN{
	if(eval{ require Test::Warn }){
		plan tests => 3;
	}
	else{
		plan skip_all => 'Test::Warn required';
		exit;
	}
}

use Test::Warn;

warning_like {
	use Acme::StringFormat;
	my $s = 'foo' % '[%s]';
} qr/mismatch/, 'arguments mismatch';

warning_like {
	use Acme::StringFormat;
	my $s = '%%' % 'foo';
} qr/mismatch/, 'arguments mismatch';

warning_like{
	use Acme::StringFormat;
	my $s = '%d' % 'foo';
} 'numeric', 'type-mismatched argument';

