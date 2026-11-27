use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use Ekorn::Pipeline qw();
use DBIx::Squirrel::Stop;

package My::Stop {
    our @ISA = 'Ekorn::Pipeline::Stop';
}

subtest 'Stop is Ekorn::Pipeline::Stop, carrying its arguments' => sub {
    is dies { Stop() }, ['Ekorn::Pipeline::Stop'], 'none';
    is dies { Stop(1, undef, 'x') }, ['Ekorn::Pipeline::Stop', 1, undef, 'x'],
        'several, undef among them';
    ref_is \&Stop, \&Ekorn::Pipeline::Stop::Stop, 'the same function';
};

subtest 'DBIx::Squirrel::Stop re-exports Stop, and is no class' => sub {
    ok !DBIx::Squirrel::Stop->isa('Ekorn::Pipeline::Stop'),
        'not a subclass of Ekorn::Pipeline::Stop';
    ok !DBIx::Squirrel::Stop->can('throw'), 'so it has no throw';
    my $sub = dies { My::Stop->throw(2) };
    isa_ok $sub, ['Ekorn::Pipeline::Stop'], "a subclass of Ekorn's";
    is $sub, ['My::Stop', 2], 'carrying its arguments';
};

subtest 'each kind of stop stops a pipeline' => sub {
    my $class = 'Ekorn::Pipeline';
    for my $throw (
        ['Stop',                  sub { Stop('last') }],
        ['a subclass of it',      sub { My::Stop->throw('last') }],
        ['Ekorn::Pipeline::Stop', sub { Ekorn::Pipeline::Stop->throw('last') }],
    ) {
        my($name, $stop) = @$throw;
        my $p = $class->new(sub { $_ == 2 ? $stop->() : $_ });
        is [$p->(1 .. 5)], [1, 'last'], $name;
    }
};

subtest 'Stop is exported by default' => sub {

    package Importing::Default {    ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Stop;
    }
    ok Importing::Default->can('Stop'), 'by default';

    package Not::Importing {        ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Stop ();
    }
    ok !Not::Importing->can('Stop'), 'not when told not to';
};

subtest 'is_stop tells a stop from anything else, on request' => sub {

    package Asking {                ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Stop qw(is_stop);
    }
    ok !Importing::Default->can('is_stop'), 'not by default';
    ok +Asking->can('is_stop'),             'on request';
    my $is_stop = \&DBIx::Squirrel::Stop::is_stop;
    ok $is_stop->(dies { Stop() }),                       "Stop's";
    ok $is_stop->(dies { My::Stop->throw }),              "a subclass's";
    ok $is_stop->(dies { Ekorn::Pipeline::Stop->throw }), "throw's";
    my $taken;
    my $p = Ekorn::Pipeline->new(sub {
        my $value = $_[0];
        local $@;
        my $ok = eval { $value == 2 ? Stop() : 1 };
        $taken = $@ unless $ok;
        return $value;
    });
    $p->(1, 2);
    ok $is_stop->($taken), 'one caught in a stage';
    ok !$is_stop->($_), 'not ' . ($_ // 'undef')
        for 'Stop used outside a pipeline', undef, '', [], bless {}, 'Other';
};

subtest 'a Stop explains itself as a string' => sub {
    is '' . dies { Stop() }, "Stop used outside a pipeline\n";
    is '' . dies { My::Stop->throw }, "Stop used outside a pipeline\n",
        'a subclass too';
};

done_testing;
