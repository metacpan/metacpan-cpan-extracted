
use Test::More;
use Test::Deep;
use Test::Lib;
use Scalar::Util qw( refaddr );

use Beam::Wire;

subtest 'method' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::MethodTest',
                method => 'cons',
                args => {
                    text => 'Hello',
                },
            },
        },
    );

    my $foo = $wire->get( 'foo' );
    isa_ok $foo, 'My::MethodTest';
    cmp_deeply $foo->got_args_hash, {
        cons => 1,
        text => 'Hello',
    };
};

subtest 'multi method' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::MethodTest',
                method => [
                    {
                        method => 'new',
                        args => { text => 'new' },
                    },
                    {
                        method => 'append',
                        args => 'append',
                    },
                ],
            },
        },
    );
    my $foo = $wire->get( 'foo' );
    cmp_deeply $foo->got_args_hash, { text => 'new; append' };
};

subtest 'chain method' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::MethodTest',
                method => [
                    {
                        method => 'new',
                        args => { text => 'new' },
                    },
                    {
                        method => 'chain',
                        return => 'chain',
                        args => { text => 'chain' },
                    },
                ],
            },
        },
    );
    my $foo = $wire->get( 'foo' );
    cmp_deeply $foo->got_args, [ text => 'new; chain' ];
};

done_testing;
