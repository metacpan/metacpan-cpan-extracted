use strict;
use warnings;

use Data::MARC::Leader::Utils;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Leader::Utils->new;
isa_ok($obj, 'Data::MARC::Leader::Utils');

# Test.
eval {
	Data::MARC::Leader::Utils->new(
		'lang' => 'bad',
	);
};
is($EVAL_ERROR, "Cannot load texts in language 'bad'.\n",
	"Cannot load texts in language 'bad' (bad).");
clean();
