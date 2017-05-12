#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use DBIx::Config;

my $tests = [
    {
        put => 
            {
                dsn => 'dbi:mysql:somedb',
                user => 'username',
                password => 'password',
            },
        get => 
            [
                'dbi:mysql:somedb',
                'username',
                'password',
                {},
            ],
        title => "Hashref connections work.",
    },
    {
        put => [ 'dbi:mysql:somedb', 'username', 'password' ],
        get => 
            [
                'dbi:mysql:somedb',
                'username',
                'password',
                {},
            ],
        title => "Array connections work.",
    },
    {
        put => [ 'DATABASE' ],
        get => [ 'DATABASE', undef, undef, {} ],
        title => "DSN gets the first element name.",
    },
    {
        put => [ 'dbi:mysql:somedb', 'username', 'password', { PrintError => 1 } ],
        get => 
        [
            'dbi:mysql:somedb',
            'username',
            'password',
            { PrintError  => 1 },

        ],
        title => "Normal option hashes pass through.",
    },
    {
        put => [ 'DATABASE', 'USERNAME', { hostname => 'hostname' } ],
        get => [ 'DATABASE', 'USERNAME', undef, { hostname => 'hostname' } ],
        title => "Ensure (string, string, hashref) format works correctly.",
    },
    {
        put => [ 'DATABASE', 'USERNAME', 'PASSWORD', { hostname => 'hostname' } ],
        get => [ 'DATABASE', 'USERNAME', 'PASSWORD', { hostname => 'hostname' } ],
        title => "Ensure (string, string, string, hashref) format works correctly.",
    },
    {
        put => [ 'DATABASE', 'U', 'P', { foo => "bar" }, { hostname => 'hostname' } ],
        get => [ 'DATABASE', 'U', 'P', { foo => "bar", hostname => 'hostname' } ],
        title => "Ensure (string, string, string, hashref, hashref) format works correctly.",
    },

];


for my $test ( @$tests ) {
    is_deeply( 
        [
            DBIx::Config->_dbi_credentials(
                DBIx::Config->_make_config( 
                    ref $test->{put} eq 'ARRAY' ? @{$test->{put}} : $test->{put}
                )
            ), 
        ],
        $test->{get}, 
        $test->{title} 
    );
}

done_testing;
