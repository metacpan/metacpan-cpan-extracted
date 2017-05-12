use strict;
use warnings;

use Test::More;
plan qw/no_plan/;

use Config::JFDI;

$ENV{XYZZY_CONFIG} = "t/assets/some_random_file.pl";

my $config = Config::JFDI->new(qw{ name xyzzy path t/assets });

ok($config->get);
is($config->get->{'Controller::Foo'}->{foo},       'bar');
is($config->get->{'Model::Baz'}->{qux},            'xyzzy');
is($config->get->{'view'},                         'View::TT');
is($config->get->{'random'},                        1);
#is($config->get->{'foo_sub'},                      '__foo(x,y)__' );
#is($config->get->{'literal_macro'},                '__literal(__DATA__)__');

$ENV{XYZZY_CONFIG} = "t/assets/some_non_existent_file.pl";

$config->reload;

ok($config->get);
is(scalar keys %{ $config->get }, 0);
