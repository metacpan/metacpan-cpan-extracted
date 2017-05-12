use strict;
use warnings;

use Test::More;

use Config::ZOMG;

eval {
    delete $ENV{$_} for qw/CATALYST_CONFIG_LOCAL_SUFFIX/;
};

$ENV{CATALYST_CONFIG} = "t/assets/some_random_file.pl";

my $config = Config::ZOMG->new(qw{ name xyzzy path t/assets env_lookup CATALYST });

ok($config->load);
is($config->load->{'Controller::Foo'}->{foo},       'bar');
is($config->load->{'Model::Baz'}->{qux},            'xyzzy');
is($config->load->{'view'},                         'View::TT');
is($config->load->{'random'},                        1);

$ENV{XYZZY_CONFIG} = "t/assets/xyzzy.pl";

$config = Config::ZOMG->new(qw{ name xyzzy path t/assets }, env_lookup => [qw/CATALYST/]);

ok($config->load);
is($config->load->{'Controller::Foo'}->{foo},       'bar');
is($config->load->{'Controller::Foo'}->{new},       'key');
is($config->load->{'Model::Baz'}->{qux},            'xyzzy');
is($config->load->{'Model::Baz'}->{another},        'new key');
is($config->load->{'view'},                         'View::TT::New');
is($config->load->{'foo_sub'},                      '__foo(x,y)__' );
is($config->load->{'literal_macro'},                '__literal(__DATA__)__');

done_testing;
