use strict;
use warnings;

use if !$ENV{AUTOMATED_TESTING}, 'Test::More' => skip_all => 'these tests are for automated testing';

use App::CPAN::Dependents 'find_all_dependents';
use HTTP::Tiny;
use MetaCPAN::Client;
use Test::More;
use Test::RequiresInternet 'clientinfo.metacpan.org' => 'https';

my $mcpan = MetaCPAN::Client->new(ua => HTTP::Tiny->new(timeout => 5), debug => 1);

my $test_module = 'JSON::Tiny';
my $test_dist = 'JSON-Tiny';

my $module_deps = find_all_dependents(module => $test_module, mcpan => $mcpan);
my $dist_deps = find_all_dependents(dist => $test_dist, mcpan => $mcpan);
ok(@$module_deps, "Found dependents for $test_module");
ok(@$dist_deps, "Found dependents for $test_dist");
is_deeply $module_deps, $dist_deps, 'Dependents for dist and module match';

my $recommended_deps = find_all_dependents(module => $test_module, recommends => 1, mcpan => $mcpan);
ok(scalar(@$recommended_deps) > scalar(@$module_deps), "Found additional recommended dependents for $test_module");

done_testing;
