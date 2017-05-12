use strict;
use warnings;
# Tests adapted from Dancer2 core t/serializer_json.t

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS;

use Dancer2::Serializer::JSONMaybeXS;

# config
{
    package MyApp;

    use Dancer2;
    our $entity;

    set engines => {
        serializer => {
            JSONMaybeXS => {
                pretty => 1,
            }
        }
    };
    set serializer => 'JSONMaybeXS';

    get '/serialize'  => sub {
        return $entity;
    };
}

my @tests = (
    {   entity  => { a      => 1, b => 2, },
        options => { pretty => 1 },
        name    => "basic hash",
    },
    {   entity  =>
          { c => [ { d => 3, e => { f => 4, g => 'word', } } ], h => 6 },
        options => { pretty => 1 },
        name    => "nested",
    },
    {   entity  => { data => "\x{2620}" x 10 },
        options => { pretty => 1, utf8 => 1 },
        name    => "utf8",
    }
);

my $app = MyApp->to_app;

for my $test (@tests) {
    my $expected = JSON::MaybeXS->new($test->{options})->encode($test->{entity});

    # Options from config
    my $serializer = Dancer2::Serializer::JSONMaybeXS->new(config => $test->{options});
    my $output = $serializer->serialize( $test->{entity} );
    is( $output, $expected, "serialize: $test->{name}" );

    $MyApp::entity = $test->{entity};
    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->( GET '/serialize' );
        is($res->content, $expected,
          "serialized content in response: $test->{name}");
    };

}


done_testing();
