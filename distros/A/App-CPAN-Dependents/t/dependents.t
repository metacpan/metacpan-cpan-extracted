use strict;
use warnings;
use App::CPAN::Dependents 'find_all_dependents';
use HTTP::Tiny;
use MetaCPAN::Client;
use Test::More;
use Test::RequiresInternet 'clientinfo.metacpan.org' => 'https';

my $mcpan = MetaCPAN::Client->new(ua => HTTP::Tiny->new(timeout => 5), debug => 1);

my $test_module = 'Dist::Zilla::PluginBundle::Author::DBOOK';
my $test_dist = 'Dist-Zilla-PluginBundle-Author-DBOOK';

my $module_deps = find_all_dependents(module => $test_module, mcpan => $mcpan);
my $dist_deps = find_all_dependents(dist => $test_dist, mcpan => $mcpan);
is_deeply $module_deps, $dist_deps, 'Dependents for dist and module match';

done_testing;
