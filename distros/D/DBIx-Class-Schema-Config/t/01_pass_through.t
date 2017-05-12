#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use DBIx::Class::Schema::Config;

my $tests = [
    {
        put => 
            {
                dsn => 'dbi:mysql:somedb',
                user => 'username',
                password => 'password',
            },
        get => 
            {
                dsn      => 'dbi:mysql:somedb',
                user     => 'username',
                password     => 'password',
            },
        title => "Hashref connections work.",
    },
    {
        put => [ 'dbi:mysql:somedb', 'username', 'password' ],
        get => 
            {
                dsn      => 'dbi:mysql:somedb',
                user     => 'username',
                password => 'password',
            },
        title => "Array connections work.",
    },
    {
        put => [ 'DATABASE' ],
        get => { dsn => 'DATABASE', user => undef, password => undef },
        title => "DSN gets the first element name.",
    },
    {
        put => [ 'dbi:mysql:somedb', 'username', 'password', { PrintError => 1 } ],
        get => 
        {
            dsn         => 'dbi:mysql:somedb',
            user        => 'username',
            password    => 'password',
            PrintError  => 1,
        },
        title => "Normal option hashes pass through.",
    },
    {
        put => [ 'DATABASE', 'USERNAME', { hostname => 'hostname' } ],
        get => { dsn => 'DATABASE', user => 'USERNAME', hostname => 'hostname' },
        title => "Ensure (string, string, hashref) format works correctly.",
    },
    {
        put => [ 'DATABASE', 'USERNAME', 'PASSWORD', { hostname => 'hostname' } ],
        get => { dsn => 'DATABASE', user => 'USERNAME', password => 'PASSWORD', hostname => 'hostname' },
        title => "Ensure (string, string, string, hashref) format works correctly.",
    },
    {
        put => [ 'DATABASE', 'U', 'P', { foo => "bar" }, { hostname => 'hostname' } ],
        get => { dsn => 'DATABASE', user => 'U', password => 'P', foo => "bar", hostname => 'hostname' },
        title => "Ensure (string, string, string, hashref, hashref) format works correctly.",
    },

];


for my $test ( @$tests ) {
    is_deeply( 
        DBIx::Class::Schema::Config->_make_connect_attrs(
            ref $test->{put} eq 'ARRAY' ? @{$test->{put}} : $test->{put}
        ), $test->{get}, $test->{title} );
}

done_testing;
