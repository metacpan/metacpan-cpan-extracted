#!/usr/bin/env perl

use strict;
use warnings;

use Try::Tiny;

use Test::More;
use Test::Fatal;
use Test::Data::Riak::Fast;

BEGIN {
    skip_unless_riak;
    use_ok('Data::Riak::Fast::Link');
}

use Data::Riak::Fast;

my $riak = Data::Riak::Fast->new(transport => Data::Riak::Fast::HTTP->new);
my $bucket_name = create_test_bucket_name;
my $bucket = $riak->bucket( $bucket_name );

=pod

So the idea here is that you can store your data using 
some kind of non-human friendly, but unique GUID

  /buckets/users/keys/<guid>

And then you create another key which is the common 
identifier for this data (ex: username on a user object)
but which actually has no data, it only has a link back 
to the canonical version of the objects which is stored
with the GUID.

  /buckets/users/keys/<username>

Then it is just a matter of doing the linkwalk from 
the bucket object and it very easy (i.e. - a single read) 
to fetch this  canonical record just using the 
common identifier.

  /buckets/users/keys/<username>/users,canonical,_/

=cut

$bucket->add( '1234' => '{"username":"bob",email":"bob@example.org"}' );
$bucket->add( 'bob' => '', {
    links => [
        $bucket->create_link( key => '1234', riaktag => 'canonical' )
    ]
});

my $results = $bucket->linkwalk('bob', [ [ 'canonical', 0 ] ]);

my ($bob) = $results->first;
isa_ok($bob, 'Data::Riak::Fast::Result');

is($bob->key, '1234', '... it is the object we expect');

remove_test_bucket($bucket);

done_testing;


