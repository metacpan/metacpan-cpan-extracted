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

my $tests = [
    {
        put => { dsn => 'SOME_DATABASE', user => '', password => '' },
        get => {
                dsn => 'dbi:SQLite:dbfile=:memory:',
                user => 'MyUser',
                password => 'MyPass',
        },
        title => "Get DB info from hashref.",
    },
    {
        put => [ 'SOME_DATABASE' ],
        get => {
                dsn  => 'dbi:SQLite:dbfile=:memory:',
                user => 'MyUser',
                password => 'MyPass',
        },
        title => "Get DB info from array.",
    },
    {
        put => { dsn => 'AWESOME_DB' },
        get => {
                dsn  => 'dbi:mysql:dbname=epsilon', 
                user => 'Bravo',
                password => 'ShiJulIanDav',
        },
        title => "Get DB from hashref without user and pass.",
    },
    {
        put => [ 'dbi:mysql:dbname=foo', 'username', 'password' ],
        get => {
            dsn  => 'dbi:mysql:dbname=foo',
            user => 'username',
            password => 'password',
        },
        title => "Pass through of normal ->connect as array.",
    },
    {
        put => {
            dsn  => 'dbi:mysql:dbname=foo', 
            user => 'username', 
            password => 'password'
        },
        get => {
            dsn  => 'dbi:mysql:dbname=foo',
            user => 'username',
            password => 'password',
        },
        title => "Pass through of normal ->connect as hashref.",
    },
    {
        put => [ 'OPTIONS' ],
        get => {
            dsn => 'dbi:SQLite:dbfile=:memory:',
            user => 'Happy',
            password => 'User',
            TRACE_LEVEL => 5,
        },
        title => "Default loading",
    },
    {
        put => [ 'OPTIONS', undef, undef, { TRACE_LEVEL => 10 } ],
        get => {
            dsn => 'dbi:SQLite:dbfile=:memory:',
            user => 'Happy',
            password => 'User',
            TRACE_LEVEL => 10,
        },
        title => "Override of replaced key works.",
    },
    {
        put => [ 'OPTIONS', undef, undef, { TRACE_LEVEL => 10, MAGIC => 1 } ],
        get => {
            dsn => 'dbi:SQLite:dbfile=:memory:',
            user => 'Happy',
            password => 'User',
            TRACE_LEVEL => 10,
            MAGIC => 1,
        },
        title => "Override for non-replaced key works.",
    },
    {
        put => [ 'OPTIONS', { TRACE_LEVEL => 10, MAGIC => 1 } ],
        get => {
            dsn => 'dbi:SQLite:dbfile=:memory:',
            user => 'Happy',
            password => 'User',
            TRACE_LEVEL => 10,
            MAGIC => 1,
        },
        title => "Override for non-replaced key works, without undefing",
    },
    {
        put => [ 'OPTIONS', "Foobar", undef, { TRACE_LEVEL => 10 } ],
        get => {
            dsn => 'dbi:SQLite:dbfile=:memory:',
            user => 'Foobar',
            password => 'User',
            TRACE_LEVEL => 10,
        },
        title => "Overriding the username works.",
    },
    {
        put => [ 'OPTIONS', "Foobar", { TRACE_LEVEL => 10 } ],
        get => {
            dsn => 'dbi:SQLite:dbfile=:memory:',
            user => 'Foobar',
            password => 'User',
            TRACE_LEVEL => 10,
        },
        title => "Overriding the username works without undefing password.",
    },
    {
        put => [ 'OPTIONS', undef, "Foobar", { TRACE_LEVEL => 10 } ],
        get => {
            dsn => 'dbi:SQLite:dbfile=:memory:',
            user => 'Happy',
            password => 'Foobar',
            TRACE_LEVEL => 10,
        },
        title => "Overriding the password works.",
    },
    {
        put => [ 'OPTIONS', "BleeBaz", "Foobar", { TRACE_LEVEL => 10 } ],
        get => {
            dsn => 'dbi:SQLite:dbfile=:memory:',
            user => 'BleeBaz',
            password => 'Foobar',
            TRACE_LEVEL => 10,
        },
        title => "Overriding the user and password works.",
    }, 
];

for my $test ( @$tests ) {
    is_deeply( 
        DBIx::Class::Schema::Config->load_credentials( 
            DBIx::Class::Schema::Config->_make_connect_attrs(
                ref $test->{put} eq 'ARRAY' ? @{$test->{put}} : $test->{put})
        ), $test->{get}, $test->{title} );
}

done_testing;
