#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use DBIx::Class::Schema::Config;

{
    package Config::Any;

    $INC{"Config/Any.pm"} = __FILE__;
    
    sub load_stems {
        return [
            {
                'some_file' => { 
                    SOME_DATABASE => {
                        dsn => 'dbi:SQLite:dbfile=:memory:',
                        user => 'MyUser',
                        password => 'MyPass',
                    },
                    AWESOME_DB => {
                        dsn => 'dbi:mysql:dbname=epsilon', 
                        user => 'Bravo',
                        password => 'ShiJulIanDav',
                    },
                    OPTIONS => {
                        dsn => 'dbi:SQLite:dbfile=:memory:',
                        user => 'Happy',
                        password => 'User',
                        TRACE_LEVEL => 5,
                    }
                },
            },
            {
                'some_other_file' => {
                    SOME_DATABASE => {
                        dsn => 'dbi:mysql:dbname=acronym', 
                        user => 'YawnyPants',
                        password => 'WhyDoYouHateUs?',
                    },
                },
            }
        ]
    }
}

ok my $ref = DBIx::Class::Schema::Config->config;
is_deeply( $ref, "Config::Any"->load_stems, "Loaded correct data set." );

is $ref->[0]->{some_file} = undef, undef,  "Changed reference returned by config.";



is_deeply( 
    DBIx::Class::Schema::Config->config, 
    "Config::Any"->load_stems,
    "Changes to a ref of ::config's return does not change future invocations."
);


done_testing;
