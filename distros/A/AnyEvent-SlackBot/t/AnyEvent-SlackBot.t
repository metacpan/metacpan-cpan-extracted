use Modern::Perl;
use Test::More qw(no_plan);

my $class='AnyEvent::SlackBot';

use_ok($class);
require_ok($class);

# most of our testing is functional

done_testing;
