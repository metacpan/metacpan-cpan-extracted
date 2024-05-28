use strict;
use warnings;

use Data::Person;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::Person->new;
is($obj->email, undef, 'Get email (undef - default).');

# Test.
$obj = Data::Person->new(
	'email' => 'skim@cpan.org',
);
is($obj->email, 'skim@cpan.org', 'Get email (skim@cpan.org).');

# Test.
eval {
	Data::Person->new(
		'email' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'email' doesn't contain valid email.\n",
	"Parameter 'email' doesn't contain valid email.");
clean();
