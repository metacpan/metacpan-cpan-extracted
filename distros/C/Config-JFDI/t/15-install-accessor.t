use strict;
use warnings;

use Test::More;
plan qw/no_plan/;

use Config::JFDI;

my $config = Config::JFDI->new(qw{ name Xyzzy::Catalyst path t/assets install_accessor A::Random::Package });

ok(!Xyzzy::Catalyst->can("config"));
ok(A::Random::Package->config);
$config = A::Random::Package->config;
ok($config);
is($config->{'Controller::Foo'}->{foo},       'bar');
is($config->{'Model::Baz'}->{qux},            'xyzzy');
is($config->{'view'},                         'View::TT');

$config = Config::JFDI->new(qw{ name Xyzzy::Catalyst path t/assets install_accessor 1 });

ok(Xyzzy::Catalyst->config);
$config = Xyzzy::Catalyst->config;
ok($config);
is($config->{'Controller::Foo'}->{foo},       'bar');
is($config->{'Model::Baz'}->{qux},            'xyzzy');
is($config->{'view'},                         'View::TT');

