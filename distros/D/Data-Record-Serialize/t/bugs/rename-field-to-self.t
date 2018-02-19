#! perl

use Test2::V0;

use Data::Record::Serialize;

use lib 't/lib';

{
    package Data::Record::Serialize::Encode::pass;
    use Moo::Role;

    use Types::Standard 'HashRef';

    has dest => (
        is       => 'ro',
        isa      => HashRef,
        required => 1,
    );

    sub encode { %{ $_[0]->dest } = %{ $_[1] } }

    with 'Data::Record::Serialize::Role::Encode';
}

subtest 'test role' => sub {
    my %dest;

    my $s = Data::Record::Serialize->new(
        encode => 'pass',
        dest   => \%dest,
        sink   => 'null'
    );

    $s->send( { foo => 1 } );

    is( \%dest, { foo => 1 }, "role works" );
};


subtest 'rename field to something else' => sub {
    my %dest;

    my $s = Data::Record::Serialize->new(
        encode        => 'pass',
        dest          => \%dest,
        sink          => 'null',
        rename_fields => { foo => 'bar' } );

    $s->send( { foo => 1 } );

    is( \%dest, { bar => 1 }, "rename foo to bar" );
};

subtest 'rename field to itself' => sub {
    my %dest;

    my $s = Data::Record::Serialize->new(
        encode        => 'pass',
        dest          => \%dest,
        sink          => 'null',
        rename_fields => { foo => 'foo' } );

    $s->send( { foo => 1 } );

    is( \%dest, { foo => 1 }, "rename foo to foo" );
};


done_testing;
