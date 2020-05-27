package Transfer;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


extends 'Data::AnyXfer';
with 'Data::AnyXfer::From::JSON';

use namespace::autoclean;

1;

# ...

package main;

use Data::AnyXfer::Test::Kit;

note " - - - json input tests - - - ";

foreach my $test ( tests() ) {

    my $transfer = Transfer->new( json => $test->{in} );

    is_deeply    #
        $transfer->json,
        { author => 'Douglas Adams' },
        "output for " . $test->{name};
}

note " - - - find method test - - - ";

my $object = Transfer->new( json => '{}' );
my $doc = { bucket => { data => { documents => [ { name => 'Adam' } ] } } };

is_deeply $object->_find( $doc, "bucket" ),
    { data => { documents => [ { name => 'Adam' } ], } },
    "found data with scalar value";

is_deeply $object->_find( $doc, qw/bucket data documents/ ),
    [ { name => 'Adam' } ],
    "found data with list values";

dies_ok { $object->_find( $doc, "documents" ) }
"unable to find data with non-existant key";

note " - - - fetch_next tests - - - ";

my $fruit = Transfer->new(
    json => '{ "documents" : [ "apples", "oranges", "pears"] }'    #
);

is $fruit->fetch_next, "apples";
is $fruit->fetch_next, "oranges";
is $fruit->fetch_next, "pears";
is $fruit->fetch_next, undef;

sub tests {
    return (
        {   name => 'json represented as a hash',
            in   => { author => 'Douglas Adams', },
        },
        {   name => 'json from inline string',
            in   => '{ "author" : "Douglas Adams" }',
        },
        {   name => 'json from a file',
            in   => file('t/lib/author.json')
        }
    );
}

done_testing;

1;
