use strict;
use warnings;

use Test::More;

# ABSTRACT: Make sure subclassing the name is easy and lazy

BEGIN {
    eval "require Moo; 1"
      or plan skip_all => "Moo required for this test";
}

use CPAN::Changes::Group;

{

    package CustomGroup;

    use Moo;
    extends 'CPAN::Changes::Group';

    has 'name'    => ( is => ro =>, lazy => 1, builder => '_build_name' );
    has 'flavour' => ( is => ro =>, lazy => 1, builder => '_build_flavour' );

    sub _build_name {
        my ($self) = @_;
        return 'Custom::Name / ' . $self->flavour;
    }

    sub _build_flavour {
        return 'Vanilla';
    }
}

subtest 'nameonly' => sub {
    my $object = CustomGroup->new( name => 'Bob' );

    is( $object->name,    'Bob',     'Constructor attribute passthrough' );
    is( $object->flavour, 'Vanilla', 'Default flavour still exists' );
};

subtest 'flavouronly' => sub {
    my $object = CustomGroup->new( flavour => 'Earwax' );

    is(
        $object->name,
        'Custom::Name / Earwax',
        'Constructor attribute affects name lazily'
    );
    is( $object->flavour, 'Earwax', 'Passed flavour propagates' );
};

subtest 'noargs' => sub {
    my $object = CustomGroup->new();

    is(
        $object->name,
        'Custom::Name / Vanilla',
        'Default attribute affects name lazily'
    );
    is( $object->flavour, 'Vanilla', 'Default flavour propagates' );
};

done_testing;
