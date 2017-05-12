use strict;
use warnings;

use Test::More;

use Config::ZOMG;

my $config = Config::ZOMG->new(qw{ name xyzzy path t/assets });

ok($config->load);
is($config->load->{'Controller::Foo'}->{foo},         'bar');
is($config->load->{'Controller::Foo'}->{new},         'key');
is($config->load->{'Model::Baz'}->{qux},              'xyzzy');
is($config->load->{'Model::Baz'}->{another},          'new key');
is($config->load->{'view'},                           'View::TT::New');
is($config->load->{'foo_sub'},                        '__foo(x,y)__');
is($config->load->{'literal_macro'},                  '__literal(__DATA__)__');

done_testing;
