#! /usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Deep;

BEGIN {
        use_ok( 'Config::INI::Serializer' );
}

# expected data
my $data = do "t/testdata.pl";

# from ini
my $ini_content;
my $INI;
open $INI, "<", "t/testdata.ini" and do {
        local $/;
        $ini_content = <$INI>;
        close $INI;
};

# deserialize
my $ini_data = Config::INI::Serializer->new->deserialize($ini_content);

# test
is ($ini_data->{tests_run},           8,                            "data compare - number is expected");
is ($ini_data->{tests_run},           $data->{tests_run},           "data compare - number is the same");
is ($ini_data->{start_time},          "1236463400.25151",           "data compare - string is expected");
is ($ini_data->{start_time},          $data->{start_time},          "data compare - string is the same");
is ($ini_data->{lines}{0}{as_string}, "TAP version 13",             "data compare - arrays become hashes - value is expected");
is ($ini_data->{lines}{0}{as_string}, $data->{lines}[0]{as_string}, "data compare - arrays become hashes - value is the same");

# round trip
my $ini_content_generated   = Config::INI::Serializer->new->serialize($data);
my $ini_data_from_generated = Config::INI::Serializer->new->deserialize($ini_content_generated);
cmp_deeply(
           $ini_data_from_generated,
           $ini_data,
           "deserializing its own serialized data gets same data again"
         );

done_testing;
