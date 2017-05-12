use strict;
use warnings;

use Test::More 0.88;

use Chloro::Types qw( Int Str );

{
    package Role1;

    use Moose::Role;
    use Chloro;

    use Chloro::Types qw( Int Str );

    field foo => ( isa => Str );

    group bar => (
        repetition_key => 'bar_id',
        (
            field size => (
                isa      => Int,
                required => 1,
            )
        ),
        ( field smell => ( isa => Str ) ),
    );
}

{
    package Role2;

    use Moose::Role;
    use Chloro;

    use Chloro::Types qw( Int Str );

    field baz => ( isa => Str );

    group buz => (
        repetition_key => 'buz_id',
        ( field x => ( isa => Int ) ),
        ( field y => ( isa => Str ) ),
    );
}

{
    package Class1;

    use Moose;

    with 'Role1';
}

{
    my $form = Class1->new();

    my %fields = map { $_->name() => { $_->dump() } } $form->fields();

    is_deeply(
        \%fields, {
            foo => {
                type     => Str,
                required => 0,
                secure   => 0,
            },
        },
        'field metadata'
    );

    my %groups = map { $_->name() => { $_->dump() } } $form->groups();

    is_deeply(
        \%groups, {
            bar => {
                repetition_key => 'bar_id',
                fields           => {
                    size => {
                        type     => Int,
                        required => 1,
                        secure   => 0,
                    },
                    smell => {
                        type     => Str,
                        required => 0,
                        secure   => 0,
                    },
                },
            },
        },
        'group metadata'
    );
}

{
    package Class2;

    use Moose;

    with 'Role1', 'Role2';
}

{
    my $form = Class2->new();

    my %fields = map { $_->name() => { $_->dump() } } $form->fields();

    is_deeply(
        \%fields, {
            foo => {
                type     => Str,
                required => 0,
                secure   => 0,
            },
            baz => {
                type     => Str,
                required => 0,
                secure   => 0,
            },
        },
        'field metadata'
    );

    my %groups = map { $_->name() => { $_->dump() } } $form->groups();

    is_deeply(
        \%groups, {
            bar => {
                repetition_key => 'bar_id',
                fields           => {
                    size => {
                        type     => Int,
                        required => 1,
                        secure   => 0,
                    },
                    smell => {
                        type     => Str,
                        required => 0,
                        secure   => 0,
                    },
                },
            },
            buz => {
                repetition_key => 'buz_id',
                fields           => {
                    x => {
                        type     => Int,
                        required => 0,
                        secure   => 0,
                    },
                    y => {
                        type     => Str,
                        required => 0,
                        secure   => 0,
                    },
                },
            },
        },
        'group metadata'
    );
}

{
    package Class3;

    use Moose;

    with 'Role1';
    with 'Role2';
}

{
    my $form = Class3->new();

    my %fields = map { $_->name() => { $_->dump() } } $form->fields();

    is_deeply(
        \%fields, {
            foo => {
                type     => Str,
                required => 0,
                secure   => 0,
            },
            baz => {
                type     => Str,
                required => 0,
                secure   => 0,
            },
        },
        'field metadata'
    );

    my %groups = map { $_->name() => { $_->dump() } } $form->groups();

    is_deeply(
        \%groups, {
            bar => {
                repetition_key => 'bar_id',
                fields           => {
                    size => {
                        type     => Int,
                        required => 1,
                        secure   => 0,
                    },
                    smell => {
                        type     => Str,
                        required => 0,
                        secure   => 0,
                    },
                },
            },
            buz => {
                repetition_key => 'buz_id',
                fields           => {
                    x => {
                        type     => Int,
                        required => 0,
                        secure   => 0,
                    },
                    y => {
                        type     => Str,
                        required => 0,
                        secure   => 0,
                    },
                },
            },
        },
        'group metadata'
    );
}

done_testing();
