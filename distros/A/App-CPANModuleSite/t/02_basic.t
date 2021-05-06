use Test::More;

use App::CPANModuleSite;

ok(my $app = App::CPANModuleSite->new('App-CPANModuleSite'),
   'Got an object');

isa_ok($app, 'App::CPANModuleSite', 'Got the right kind of object');

done_testing;
