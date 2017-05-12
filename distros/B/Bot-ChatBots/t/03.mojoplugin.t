use strict;
use Test::More tests => 12;
use Mock::Quick;
use Test::Exception;

BEGIN {
   (my $subdir = __FILE__) =~ s{t$}{d}mxs;
   unshift @INC, $subdir;
}

eval { require Bot::ChatBots::Whatever; }
  or plan 'skip_all' => 'most probably, no Mojolicious available';

is(Bot::ChatBots::Whatever->helper_name,
   'chatbots.whatever', 'helper_name');

my $message;
my $log = qobj(debug => qmeth { $message = $_[1] },);

my ($helper_name, $helper);
my $app = qobj(
   log    => $log,
   helper => qmeth { (undef, $helper_name, $helper) = @_ },
);

my $plugin;
lives_ok { $plugin = Bot::ChatBots::Whatever->new }
'instantiation of object lives';

isa_ok $plugin, 'Bot::ChatBots::Whatever';

lives_ok { $plugin->register($app) } 'registration lives';

is $message, 'helper chatbots.whatever registered', 'log debug message';
is $helper_name, 'chatbots.whatever', 'helper name';

# string comparison is fine here
is $helper->(), $plugin, 'helper sub';

($message, $helper_name, $helper) = ();

lives_ok {
   $plugin->register(
      $app,
      {
         instances => [[Something => app => 'overridden', foo => 'bar'],]
      }
   );
} ## end lives_ok
'more complex instantiation lives';

my @instances = @{$plugin->instances};
is scalar(@instances), 1, 'one instance registered';
isa_ok $instances[0], 'Bot::ChatBots::Whatever::Something';
is $instances[0]->foo, 'bar', 'instance seems right';

# string comparison is fine here
is $instances[0]->app, $app, 'app parameter was overridden';

done_testing();
