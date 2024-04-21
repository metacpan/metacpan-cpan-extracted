use strict;
use warnings;

use App::CPAN::Get::MetaCPAN;
use English;
use Error::Pure::Utils qw(clean);
use Test::LWP::UserAgent;
use Test::MockObject;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = App::CPAN::Get::MetaCPAN->new;
isa_ok($obj, 'App::CPAN::Get::MetaCPAN');

# Test.
$obj = App::CPAN::Get::MetaCPAN->new(
	'lwp_user_agent' => Test::LWP::UserAgent->new,
);
isa_ok($obj, 'App::CPAN::Get::MetaCPAN');

# Test.
eval {
	App::CPAN::Get::MetaCPAN->new(
		'lwp_user_agent' => 'string',
	);
};
is($EVAL_ERROR, "Parameter 'lwp_user_agent' must be a LWP::UserAgent instance.\n",
	"Parameter 'lwp_user_agent' must be a LWP::UserAgent instance.");
clean();

# Test.
my $mock = Test::MockObject->new;
eval {
	App::CPAN::Get::MetaCPAN->new(
		'lwp_user_agent' => $mock,
	);
};
is($EVAL_ERROR, "Parameter 'lwp_user_agent' must be a LWP::UserAgent instance.\n",
	"Parameter 'lwp_user_agent' must be a LWP::UserAgent instance.");
clean();

# Test.
eval {
	App::CPAN::Get::MetaCPAN->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();
