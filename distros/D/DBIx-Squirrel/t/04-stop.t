use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel::Pipeline;
use DBIx::Squirrel::Stop;

package My::Stop {
    our @ISA = 'DBIx::Squirrel::Stop';
}

subtest 'Stop is Ekorn::Pipeline::Stop, carrying its arguments' => sub {
    is dies { Stop() }, ['Ekorn::Pipeline::Stop'], 'none';
    is dies { Stop(1, undef, 'x') }, ['Ekorn::Pipeline::Stop', 1, undef, 'x'],
        'several, undef among them';
    ref_is \&Stop, \&Ekorn::Pipeline::Stop::Stop, 'the same function';
};

subtest 'throw is blessed into the class it was called on' => sub {
    my $stop = dies { DBIx::Squirrel::Stop->throw(1) };
    is ref($stop), 'DBIx::Squirrel::Stop',      'the class itself';
    is $stop,      ['DBIx::Squirrel::Stop', 1], 'carrying its arguments';
    isa_ok $stop, ['Ekorn::Pipeline::Stop'],
        'which is an Ekorn::Pipeline::Stop';

    my $sub = dies { My::Stop->throw(2) };
    is ref($sub), 'My::Stop', 'a subclass';
    isa_ok $sub, ['DBIx::Squirrel::Stop', 'Ekorn::Pipeline::Stop'],
        'which is still both';
    is $sub, ['My::Stop', 2], 'carrying its arguments';
};

subtest 'each kind of stop stops a pipeline' => sub {
    my $class = 'DBIx::Squirrel::Pipeline';
    for my $throw (
        ['Stop',                  sub { Stop('last') }],
        ['DBIx::Squirrel::Stop',  sub { DBIx::Squirrel::Stop->throw('last') }],
        ['a subclass of it',      sub { My::Stop->throw('last') }],
        ['Ekorn::Pipeline::Stop', sub { Ekorn::Pipeline::Stop->throw('last') }],
    ) {
        my($name, $stop) = @$throw;
        my $p = $class->new(sub { $_ == 2 ? $stop->() : $_ });
        is [$p->(1 .. 5)], [1, 'last'], $name;
    }
};

subtest 'Stop is exported by default' => sub {

    package Importing {    ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Stop;
    }
    ok Importing->can('Stop'), 'by default';

    package Not::Importing {    ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Stop ();
    }
    ok !Not::Importing->can('Stop'), 'not when told not to';
};

subtest 'a Stop explains itself as a string' => sub {
    is '' . dies { Stop() }, "Stop used outside a pipeline\n";
    is '' . dies { My::Stop->throw }, "Stop used outside a pipeline\n",
        'a subclass too';
};

done_testing;
