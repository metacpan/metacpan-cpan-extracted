use strict;
use warnings;

use Test::More;
plan qw/no_plan/;

use Config::JFDI;

my $config = Config::JFDI->new(qw{ name xyzzy path t/assets });

ok($config->get);
is($config->get->{'Controller::Foo'}->{foo},         'bar');
is($config->get->{'Controller::Foo'}->{new},         'key');
is($config->get->{'Model::Baz'}->{qux},              'xyzzy');
is($config->get->{'Model::Baz'}->{another},          'new key');
is($config->get->{'view'},                           'View::TT::New');
#is($config->get->{'foo_sub'},                       'x-y');
is($config->get->{'foo_sub'},                        '__foo(x,y)__');
#is($config->get->{'literal_macro'},                 '__DATA__');
is($config->get->{'literal_macro'},                  '__DATA__');

ok(1);
