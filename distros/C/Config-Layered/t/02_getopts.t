#!/usr/bin/perl
use warnings;
use strict;
use Config::Layered;
use Test::More;

my $tests = [
    {
        put => { verbose => 1, run => 0, },
        argv => [ qw( ) ],
        get => { verbose => 1, run => 0, },
        title => "Flags - Change Neither",
    },
    {
        put => { verbose => 1, run => 0, },
        argv => [ qw( --run --noverbose ) ],
        get => { verbose => 0, run => 1, },
        title => "Flags - Change Both",
    },
    {
        put => { verbose => 1, run => 0, },
        argv => [ qw( --noverbose ) ],
        get => { verbose => 0, run => 0, },
        title => "Flags - Change One",
    },
    {
        put => { verbose => 1, run => 0, },
        argv => [ qw( --norun --verbose ) ],
        get => { verbose => 1, run => 0, },
        title => "Flags - Same Set",
    },
    {
        put => { verbose => "yes", run => "no", },
        argv => [ qw() ],
        get => { verbose => "yes", run => "no", },
        title => "Strings -- Change Neither",
    },
    {
        put => { verbose => "yes", run => "no", },
        argv => [ qw( --verbose no ) ],
        get => { verbose => "no", run => "no", },
        title => "Strings -- Change One",
    },
    {
        put => { verbose => "yes", run => "no", },
        argv => [ qw( --verbose no --run yes ) ],
        get => { verbose => "no", run => "yes", },
        title => "Strings -- Change Both",
    },
    {
        put => { verbose => "yes", run => "no", },
        argv => [ qw( --verbose yes --run no) ],
        get => { verbose => "yes", run => "no", },
        title => "Strings -- Same Set",
    },
    {
        put => { verbose => 1, run => "yes", },
        argv => [ qw() ],
        get => { verbose => 1, run => "yes", },
        title => "Flags + Strings -- Change Neither",
    },
    {
        put => { verbose => 0, run => "yes", },
        argv => [ qw( --verbose --run no) ],
        get => { verbose => 1, run => "no", },
        title => "Flags + Strings -- Change Both",
    },
    {
        put => { verbose => 1, run => "yes", },
        argv => [ qw( --run no ) ],
        get => { verbose => 1, run => "no", },
        title => "Flags + Strings -- Change One",
    },
    {
        put => { verbose => 1, run => "yes", },
        argv => [ qw( --verbose --run yes) ],
        get => { verbose => 1, run => "yes", },
        title => "Flags + Strings -- Set Both",
    },

    {
        put => { verbose => 1, run => 0, foo => [ qw( bar blee ) ] },
        argv => [ qw() ],
        get => { verbose => 1, run => 0, foo => [ qw( bar blee ) ] },
        title => "Flags + Strings + Array Ref -- Change Nothing",
    },
    {
        put => { verbose => 1, run => 0, foo => [ qw( bar blee ) ] },
        argv => [ qw( --foo bar --foo blee --foo this ) ],
        get => { verbose => 1, run => 0, foo => [ qw( bar blee this ) ] },
        title => "Flags + Strings + Array Ref - Override Array",
    },
    {
        put => { verbose => 1, run => 0, foo => [ qw( bar blee ) ] },
        argv => [ qw( --foo foo ) ],
        get => { verbose => 1, run => 0, foo => [ qw( foo ) ] },
        title => "Flags + Strings + Array Ref -- Override Array, Blanked",
    },
    {
        put => { verbose => 1, run => 0, foo => [ qw( bar blee ) ] },
        argv => [ qw( --foo bar --foo blee ) ],
        get => { verbose => 1, run => 0, foo => [ qw( bar blee ) ] },
        title => "Flags + Strings + Array Ref -- Set ",
    },
    {
        put => { verbose => 1, run => 0, foo => [ qw( bar blee ) ], blee => { foo => 1 } },
        argv => [ qw() ],
        get => { verbose => 1, run => 0, foo => [ qw( bar blee ) ], blee => { foo => 1 } },
        title => "Flags + Strings + Array Ref + Hashref -- Nothing Changed",
    },
    {
        put => { verbose => 1, run => 0, foo => [ qw( bar blee ) ], blee => { foo => 1 } },
        argv => [ qw( --blee foo=5 ) ],
        get => { verbose => 1, run => 0, foo => [ qw( bar blee ) ], blee => { foo => 5 } },
        title => "Flags + Strings + Array Ref + Hashref -- Change Value",
    },
    {
        put => { verbose => 1, run => 0, foo => [ qw( bar blee ) ], blee => { foo => 1 } },
        argv => [ qw( --blee bar=1) ],
        get => { verbose => 1, run => 0, foo => [ qw( bar blee ) ], blee => { foo => 1, bar => 1 } },
        title => "Flags + Strings + Array Ref + Hashref -- Add To Hashref",
    },
];

for my $test ( @$tests ) {
    @ARGV = @{ $test->{argv} }; # Simulate command line input.
    is_deeply( Config::Layered->load_config( default => $test->{put} ), 
        $test->{get}, 
        $test->{title});
}

done_testing;
