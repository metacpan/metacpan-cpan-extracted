use strict;
use warnings;

use App::Kramerius::To::Images;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = App::Kramerius::To::Images->new;
isa_ok($obj, 'App::Kramerius::To::Images');

# Test.
eval {
	App::Kramerius::To::Images->new(
		'lwp_user_agent' => 'string',
	);
};
is($EVAL_ERROR, "Parameter 'lwp_user_agent' must be a LWP::UserAgent instance.\n",
	"Parameter 'lwp_user_agent' must be a LWP::UserAgent instance.");
clean();
