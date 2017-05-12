#!/usr/bin/perl
use warnings;
use strict;
use Config::Layered;
use Test::More;

my $tests = [
    {
        put => {  },
        argv => [ qw( ) ],
        get => { bar => [ qw( this that ) ], foo => "bar", blee => "baz" },
        title => "Default file works.",
    },
    {
        put => { foo => "blee"  },
        argv => [ qw( ) ],
        get => { bar => [ qw( this that ) ], foo => "bar", blee => "baz" },
        title => "Config preferred over source.",
    },
    {
        put => { foo => "blee"  },
        argv => [ qw( --foo blee ) ],
        get => { bar => [ qw( this that ) ], foo => "blee", blee => "baz" },
        title => "CLI preferred over config.",
    },
    {
        put => { foo => "blee", baz => "boom",  },
        argv => [ qw( --foo blee ) ],
        get => { bar => [ qw( this that ) ], foo => "blee", blee => "baz", baz => "boom" },
        title => "Source extends config file.",
    },
];

for my $test ( @$tests ) {
    @ARGV = @{ $test->{argv} }; # Simulate command line input.
    is_deeply( Config::Layered->load_config( file => "t/etc/config", default => $test->{put} ), 
        $test->{get}, 
        $test->{title});
}

done_testing;
