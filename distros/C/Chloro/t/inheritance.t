use strict;
use warnings;

use Test::More 0.88;

use Chloro::Types qw( Int Str );

{
    package Parent1;

    use Moose;
    use Chloro;

    use Chloro::Types qw( Str );

    field parent => (
        isa => Str,
    );
}

{
    package Child1;

    use Moose;
    use Chloro;

    use Chloro::Types qw( Str );

    extends 'Parent1';

    field child => (
        isa => Str,
    );
}

{
    my $form = Child1->new();

    my %fields = map { $_->name() => { $_->dump() } } $form->fields();

    is_deeply(
        \%fields, {
            parent => {
                type     => Str,
                required => 0,
                secure   => 0,
            },
            child => {
                type     => Str,
                required => 0,
                secure   => 0,
            },
        },
        'field metadata includes parent class fields'
    );
}

{
    package Child2;

    use Moose;
    use Chloro;

    use Chloro::Types qw( Int Str );

    extends 'Parent1';

    field parent => (
        isa      => Int,
        required => 1,
    );

    field child => (
        isa => Str,
    );
}

{
    my $form = Child2->new();

    my %fields = map { $_->name() => { $_->dump() } } $form->fields();

    is_deeply(
        \%fields, {
            parent => {
                type     => Int,
                required => 1,
                secure   => 0,
            },
            child => {
                type     => Str,
                required => 0,
                secure   => 0,
            },
        },
        'field metadata shows child overriding parent field'
    );
}

{
    package NotChloro;

    use Moose;

    sub foo { }
}

{
    package Child3;

    use Moose;
    use Chloro;

    use Chloro::Types qw( Str );

    extends 'Parent1', 'NotChloro';

    field child => (
        isa => Str,
    );
}

{
    my $form = Child3->new();

    my %fields = map { $_->name() => { $_->dump() } } $form->fields();

    is_deeply(
        \%fields, {
            parent => {
                type     => Str,
                required => 0,
                secure   => 0,
            },
            child => {
                type     => Str,
                required => 0,
                secure   => 0,
            },
        },
        'field metadata includes parent class fields - child also has non-Chloro parent'
    );
}

{
    package Parent4;

    use Moose;
    use Chloro;

    use Chloro::Types qw( Str );

    group parent => (
        repetition_key => 'parent_id',
        (
            field name => (
                isa => Str,
            )
        )
    );
}

{
    package Child4;

    use Moose;
    use Chloro;

    use Chloro::Types qw( Str );

    extends 'Parent4';

    group child => (
        repetition_key => 'child_id',
        (
            field name => (
                isa => Str,
            )
        )
    );
}

{
    my $form = Child4->new();

    my %groups = map { $_->name() => { $_->dump() } } $form->groups();

    is_deeply(
        \%groups, {
            parent => {
                repetition_key => 'parent_id',
                fields           => {
                    name => {
                        type     => Str,
                        required => 0,
                        secure   => 0,
                    },
                },
            },
            child => {
                repetition_key => 'child_id',
                fields           => {
                    name => {
                        type     => Str,
                        required => 0,
                        secure   => 0,
                    },
                },
            },
        },
        'group metadata includes parent class groups'
    );
}

done_testing();
