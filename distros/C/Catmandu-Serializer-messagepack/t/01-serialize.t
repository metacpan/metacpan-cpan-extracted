#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Catmandu::Serializer::messagepack');
my $serializer;

lives_ok(sub{ $serializer = Catmandu::Serializer::messagepack->new(); });
my $record = { a => "b", c => { d => { e => "f" } } };

is_deeply(
    $serializer->deserialize(
        $serializer->serialize($record)
    ), $record
);

done_testing 3;
