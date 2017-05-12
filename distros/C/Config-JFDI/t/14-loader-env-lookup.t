use strict;
use warnings;

use Test::More;
plan qw/no_plan/;

use Config::JFDI;

eval {
    delete $ENV{$_} for qw/CATALYST_CONFIG_LOCAL_SUFFIX/;
};

$ENV{CATALYST_CONFIG} = "t/assets/some_random_file.pl";

my $config = Config::JFDI->new(qw{ name xyzzy path t/assets env_lookup CATALYST });

ok($config->get);
is($config->get->{'Controller::Foo'}->{foo},       'bar');
is($config->get->{'Model::Baz'}->{qux},            'xyzzy');
is($config->get->{'view'},                         'View::TT');
#is($config->get->{'foo_sub'},                      '__foo(x,y)__' );
#is($config->get->{'literal_macro'},                '__literal(__DATA__)__');
is($config->get->{'random'},                        1);

$ENV{XYZZY_CONFIG} = "t/assets/xyzzy.pl";

$config = Config::JFDI->new(qw{ name xyzzy path t/assets }, env_lookup => [qw/CATALYST/]);

ok($config->get);
is($config->get->{'Controller::Foo'}->{foo},       'bar');
is($config->get->{'Controller::Foo'}->{new},       'key');
is($config->get->{'Model::Baz'}->{qux},            'xyzzy');
is($config->get->{'Model::Baz'}->{another},        'new key');
is($config->get->{'view'},                         'View::TT::New');
is($config->get->{'foo_sub'},                      '__foo(x,y)__' );
is($config->get->{'literal_macro'},                '__DATA__');
