use strict;
use warnings;

use Test::More;
use lib 't/lib';

BEGIN { $::on_demand = 1; }
use OnDemand;

plan tests => 4;

subtest 'no subcommand loaded at the start' => sub {
    ok !$OnDemand::Foo::loaded;
    ok !$OnDemand::Bar::loaded;
};


subtest 'created object, still no subcommand loaded' => sub {
    OnDemand->new_with_options;

    ok !$OnDemand::Foo::loaded;
    ok !$OnDemand::Bar::loaded;
};

subtest 'app ran, still no subcommand loaded' => sub {
    OnDemand->new_with_options->run;

    ok !$OnDemand::Foo::loaded;
    ok !$OnDemand::Bar::loaded;
};

subtest 'app ran w/ subcommand foo, only foo loaded' => sub {
    @ARGV = qw/ foo /;
    OnDemand->new_with_options->run;

    ok $OnDemand::Foo::loaded;
    ok !$OnDemand::Bar::loaded;
};
