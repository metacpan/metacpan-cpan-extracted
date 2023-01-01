use strict;
use warnings;

use App::Perl::Module::Examples;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = App::Perl::Module::Examples->new;
isa_ok($obj, 'App::Perl::Module::Examples');

# Test.
eval {
	App::Perl::Module::Examples->new(
		'bad_param' => 'foo',
	);
};
is($EVAL_ERROR, "Unknown parameter 'bad_param'.\n", "Unknown parameter 'bad_param'.");
clean();
