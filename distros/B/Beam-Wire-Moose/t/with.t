
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Beam::Wire::Moose;

{
    package Foo;
    use Moose;
    has text => (
        is => 'ro',
        isa => 'Str',
    );
}
{
    package Role::Bar;
    use Moose::Role;
    has bar => (
        is  => 'ro',
        isa => 'Str',
    );
}
{
    package Role::Baz;
    use Moose::Role;
    has baz => (
        is  => 'ro',
        isa => 'Str',
    );
}

subtest 'one role' => sub {
    my $wire = Beam::Wire::Moose->new(
        config => {
            foo => {
                class => 'Foo',
                with => 'Role::Bar',
                args => {
                    text => 'Hello',
                    bar => 'Bar',
                }
            }
        }
    );

    my $foo;
    lives_ok { $foo = $wire->get('foo') };
    isa_ok $foo, 'Foo';
    ok $foo->does( 'Role::Bar' );
    is $foo->text, 'Hello';
    is $foo->bar, 'Bar';
};

subtest 'two role' => sub {
    my $wire = Beam::Wire::Moose->new(
        config => {
            foo => {
                class => 'Foo',
                with => [ 'Role::Bar', 'Role::Baz' ],
                args => {
                    text => 'Hello',
                    bar => 'Bar',
                    baz => 'Baz',
                }
            }
        }
    );

    my $foo;
    lives_ok { $foo = $wire->get('foo') };
    isa_ok $foo, 'Foo';
    ok $foo->does( 'Role::Bar' );
    ok $foo->does( 'Role::Baz' );
    is $foo->text, 'Hello';
    is $foo->bar, 'Bar';
    is $foo->baz, 'Baz';
};

done_testing;

