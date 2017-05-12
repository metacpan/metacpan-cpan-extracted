use strict;
use warnings;

use Test::More;
plan qw/no_plan/;

use Config::JFDI;

$ENV{XYZZY_CONFIG} = "t/assets/some_non_existent_file.pl";

my $config = Config::JFDI->new(qw{ name xyzzy path t/assets no_env 1 });

ok($config->get);
is($config->get->{'Controller::Foo'}->{foo},       'bar');
is($config->get->{'Controller::Foo'}->{new},       'key');
is($config->get->{'Model::Baz'}->{qux},            'xyzzy');
is($config->get->{'Model::Baz'}->{another},        'new key');
is($config->get->{'view'},                         'View::TT::New');
is($config->get->{'foo_sub'},                      '__foo(x,y)__' );
is($config->get->{'literal_macro'},                '__DATA__');
