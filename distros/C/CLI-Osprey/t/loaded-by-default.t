use strict;
use warnings;

use Test::More;
use lib 't/lib';

use OnDemand;

plan tests => 4;

subtest 'subcommand loaded at the start' => sub {
    ok $OnDemand::Foo::loaded;
    ok $OnDemand::Bar::loaded;
};

subtest 'created object, subcommand still loaded' => sub {
    OnDemand->new_with_options;

    ok $OnDemand::Foo::loaded;
    ok $OnDemand::Bar::loaded;
};

subtest 'app ran, subcommand still loaded' => sub {
    OnDemand->new_with_options->run;

    ok $OnDemand::Foo::loaded;
    ok $OnDemand::Bar::loaded;
};

subtest 'app ran w/ subcommand foo' => sub {
    @ARGV = qw/ foo /;
    OnDemand->new_with_options->run;

    ok $OnDemand::Foo::loaded;
    ok $OnDemand::Bar::loaded;
};
