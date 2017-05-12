use strict;
use warnings;

use Test::More 0.88;

use Chloro::Field;
use Storable qw( freeze thaw );

test_clone(
    Chloro::Field->new(
        name => 'foo',
        isa  => 'Str',
    )
);

test_clone(
    Chloro::Field->new(
        name => 'foo',
        isa  => 'ArrayRef[Str]',
    )
);

SKIP:
{
    skip 'This test requires MooseX::Types', 10
        unless eval {
        require MooseX::Types;
        require MooseX::Types::Moose;
        MooseX::Types::Moose->import( 'HashRef', 'Int' );
        1;
        };

    test_clone(
        Chloro::Field->new(
            name => 'foo',
            isa  => HashRef( [ Int() ] ),
        )
    );

    eval <<'EOF';
    {
        package My::Types;

        use MooseX::Types -declare => ['MyHashRef'];
        use MooseX::Types::Moose qw( HashRef );

        subtype MyHashRef, as HashRef;
    }

    My::Types->import('MyHashRef');
EOF

    die $@ if $@;

    test_clone(
        Chloro::Field->new(
            name => 'foo',
            isa  => MyHashRef( [ Int() ] ),
        )
    );
}

sub test_clone {
    my $field = shift;

    my $cloned = thaw( freeze($field) );

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    for my $attr (qw( name type is_secure is_required default )) {
        is(
            $field->$attr(),
            $cloned->$attr(),
            "$attr is the same for cloned field object"
        );
    }
}

done_testing();
