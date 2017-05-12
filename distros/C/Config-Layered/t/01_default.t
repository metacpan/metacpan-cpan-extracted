#!/usr/bin/perl
use warnings;
use strict;
use Config::Layered;
use Test::More;

my $tests = [
    {
        put => { verbose => 1, run => 0, },
        get => { verbose => 1, run => 0, },
        title => "Flags",
    },
    {
        put => { verbose => "yes", run => "no", },
        get => { verbose => "yes", run => "no", },
        title => "Strings",
    },
    {
        put => { verbose => 1, run => "yes", },
        get => { verbose => 1, run => "yes", },
        title => "Flags + Strings",
    },
    {
        put => { verbose => 1, run => 0, foo => [ qw( bar blee ) ] },
        get => { verbose => 1, run => 0, foo => [ qw( bar blee ) ] },
        title => "Flags + Strings + Array Ref",
    },
    {
        put => { verbose => 1, run => 0, foo => [ qw( bar blee ) ], blee => { foo => 1 } },
        get => { verbose => 1, run => 0, foo => [ qw( bar blee ) ], blee => { foo => 1 } },
        title => "Flags + Strings + Array Ref + Hashref",
    },

];

for my $test ( @$tests ) {
    is_deeply( Config::Layered->load_config( default => $test->{put}, sources => [  ] ), 
        $test->{get}, 
        $test->{title} );
}

done_testing;
