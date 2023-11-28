use Test2::V0;

use Dancer2::Plugin::JsonApi::Schema;
use Dancer2::Plugin::JsonApi::Registry;

use experimental qw/ signatures /;

my $type = Dancer2::Plugin::JsonApi::Schema->new( 'type' => 'thing' );

like $type->serialize( { attr1 => 'a', id => '123' }, { foo => 1 } ) => {
    jsonapi => { version => '1.0' },
    data    => { type    => 'thing', id => '123' }
};

is( Dancer2::Plugin::JsonApi::Schema->new(
        'type' => 'thing',
        id     => 'foo'
      )->serialize( { foo => '123' } )->{data}{id} => '123',
    'custom id'
  );

my $serialized = schema_serialize(
    {   'type' => 'thing',
        id     => sub ( $data, @ ) { $data->{x} . $data->{y} },
        links  => { self => '/some/url' },
    },
    { x => '1', y => '2' }
);

is( $serialized->{data}{id} => '12',
    'custom id, function'
  );

like $serialized->{data}, { links => { self => '/some/url' } }, "links";

sub schema_serialize ( $schema, $data ) {
    return Dancer2::Plugin::JsonApi::Schema->new(%$schema)->serialize($data);
}

like(
    Dancer2::Plugin::JsonApi::Schema->new(
        type           => 'thing',
        top_level_meta => {
            foo => 1,
            bar => sub ( $data, $xtra ) {
                $xtra->{bar};
            }
        }
      )->serialize( {}, { bar => 'yup' } ),
    { meta => { foo => 1, bar => 'yup' } }
);

subtest 'attributes' => sub {
    my $serialized =
      Dancer2::Plugin::JsonApi::Schema->new( type => 'thing', )
      ->serialize( { id => 1, foo => 'bar' } );

    is $serialized->{data} => {
        type       => 'thing',
        id         => 1,
        attributes => { foo => 'bar', }
    };

};

subtest 'a single scalar == id', sub {
    my $serialized =
      Dancer2::Plugin::JsonApi::Schema->new( type => 'thing' )
      ->serialize('blah');

    is $serialized->{data} => {
        type => 'thing',
        id   => 'blah',
    };
};

subtest 'allowed_attributes', sub {
    my $serialized = Dancer2::Plugin::JsonApi::Schema->new(
        type               => 'thing',
        allowed_attributes => ['foo'],
    )->serialize( { id => 1, foo => 2, bar => 3 } );

    is $serialized->{data} => {
        type       => 'thing',
        id         => 1,
        attributes => { foo => 2, }
    };
};

subtest 'empty data', sub {
    my $serialized =
      Dancer2::Plugin::JsonApi::Schema->new( type => 'thing' )
      ->serialize(undef);

    ok( !$serialized->{data}, "there is no data" );
};

package FakeRequest {
    use Moo;
    has path => ( is => 'ro', default => '/some/path' );
}

package FakeApp {
    use Moo;
    has request => (
        is      => 'ro',
        default => sub {
            FakeRequest->new;
        }
    );
}

subtest "add the self link if tied to the app" => sub {
    my $serialized = Dancer2::Plugin::JsonApi::Schema->new(
        type     => 'thing',
        registry =>
          Dancer2::Plugin::JsonApi::Registry->new( app => FakeApp->new )
    )->serialize(undef);

    is $serialized->{links}{self} => '/some/path';
};

subtest 'attributes function' => sub {
    my $serialized = Dancer2::Plugin::JsonApi::Schema->new(
        type       => 'thing',
        attributes => sub ( $data, @ ) {
            return +{ reverse %$data },;
        },
    )->serialize( { id => 1, 'a' .. 'd' } );

    is $serialized->{data}{attributes} => { 1 => 'id', b => 'a', d => 'c' };
};

subtest 'before_serializer' => sub {
    my $serialized = Dancer2::Plugin::JsonApi::Schema->new(
        type             => 'thing',
        before_serialize => sub ( $data, @ ) {
            return +{ %$data, nbr_attrs => scalar keys %$data };
        },
    )->serialize( { id => 1, a => 'b' } );

    is $serialized->{data}{attributes}{nbr_attrs} => 2;
};

done_testing();
