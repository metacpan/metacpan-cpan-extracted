use Test::More tests => 1;
use App::Cmd::Tester;

use App::Whatsit;

my $tm_v = Test::More->VERSION;
my $tm_p = $INC{'Test/More.pm'};
my $tm_res = qq{Test::More:
	Version: $tm_v
	Path: $tm_p
};

my $result = test_app(App::Whatsit => ['Test::More']);
is($result->stdout, $tm_res, 'Test::More version looks right');