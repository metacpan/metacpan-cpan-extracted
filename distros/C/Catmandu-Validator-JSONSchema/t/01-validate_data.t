#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use Catmandu::Validator::JSONSchema;

my $tests = [
    {
        schema => {
            "required" => ["firstName", "lastName"],
            "properties"=> {
                "firstName"=> {
                    "type"=> "string",
                },
                "lastName"=> {
                    "type"=> "string",
                },
                "age"=> {
                    "description"=> "Age in years",
                    "type"=> "integer",
                    "minimum"=> 0
                }
            },
        },
        records => [
            {
                firstName => "Nicolas", lastName => "Franck"
            },
            {
                firstName => "Nicolas", age => 28
            }
        ],
        valid_count => 1,
        invalid_count => 1
    },
    {
        schema => {
            "required" => ["_id", "title"],
            "properties"=> {
                "_id"=> {
                    "type"=> "string",
                },
                "title"=> {
                    "type"=> "string",
                },
                "author"=> {
                    "type"=> "array",
                    "items" => {
                        "type" => "string"
                    },
                    minItems => 1,
                    uniqueItems => 1
                }
            },
        },
        records => [
            {
                _id => "rug01:001963301",
                title => "In gesprek met Etienne Vermeersch : een zoektocht naar waarheid",
                author => [
                    "Etienne Vermeersch",
                    "Dirk Verhofstadt"
                ]
            },
            {
                title => "In gesprek met Etienne Vermeersch : een zoektocht naar waarheid"
            },
            {
                _id => "rug01:001963301",
                title => "In gesprek met Etienne Vermeersch : een zoektocht naar waarheid",
                author => "Etienne Vermeersch"
            }
        ],
        valid_count => 1,
        invalid_count => 2
    }

];

for my $test(@$tests){
    
    my $validator;
    lives_ok(sub{
        $validator = Catmandu::Validator::JSONSchema->new(schema => $test->{schema});
    });

    $validator->validate($test->{records});
        
    is($validator->valid_count,$test->{valid_count});
    is($validator->invalid_count,$test->{invalid_count});
}

done_testing (scalar(@$tests)*3);
