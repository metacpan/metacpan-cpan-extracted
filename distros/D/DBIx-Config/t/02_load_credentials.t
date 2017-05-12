#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use Test::MockObject;
use DBIx::Config;

Test::MockObject->fake_module(
    'Config::Any',
    'load_stems' => sub {
        return [
            {
                'some_file' => { 
                    SOME_DATABASE => {
                        dsn => 'dbi:SQLite:dbfile=:memory:',
                        user => 'MyUser',
                        pass => 'MyPass',
                    },
                    AWESOME_DB => {
                        dsn => 'dbi:mysql:dbname=epsilon', 
                        user => 'Bravo',
                        pass => 'ShiJulIanDav',
                    },
                    OPTIONS => {
                        dsn => 'dbi:SQLite:dbfile=:memory:',
                        user => 'Happy',
                        pass => 'User',
                        TRACE_LEVEL => 5,
                    }
                },
                'some_other_file' => {
                    SOME_DATABASE => {
                        dsn => 'dbi:mysql:dbname=acronym', 
                        user => 'YawnyPants',
                        pass => 'WhyDoYouHateUs?',
                    },
                },
            }
        ]
    }
);

my $tests = [
    {
        put => { dsn => 'SOME_DATABASE', user => '', password => '' },
        get => {
                dsn => 'dbi:SQLite:dbfile=:memory:',
                user => 'MyUser',
                pass => 'MyPass',
        },
        title => "Get DB info from hashref.",
    },
    {
        put => [ 'SOME_DATABASE' ],
        get => {
                dsn  => 'dbi:SQLite:dbfile=:memory:',
                user => 'MyUser',
                pass => 'MyPass',
        },
        title => "Get DB info from array.",
    },
    {
        put => { dsn => 'AWESOME_DB' },
        get => {
                dsn  => 'dbi:mysql:dbname=epsilon', 
                user => 'Bravo',
                pass => 'ShiJulIanDav',
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
            pass => 'User',
            TRACE_LEVEL => 5,
        }
    }


];

for my $test ( @$tests ) {
    my $obj = DBIx::Config->new();
    is_deeply( 
        $obj->default_load_credentials( 
            $obj->_make_config(
                ref $test->{put} eq 'ARRAY' ? @{$test->{put}} : $test->{put})
        ), $test->{get}, $test->{title} );
}

done_testing;
