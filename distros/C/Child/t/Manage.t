#!/usr/bin/perl;
use strict;
use warnings;

use Test::More 0.88;
our $CLASS = 'Child';
require_ok( $CLASS );

my @children = map { $CLASS->new(sub { 1 }) } 1 .. 4;
my @get = $CLASS->all_procs;
is( @get, 0, "0 children started" );

my @all;
push @all => $_->start for @children;

@get = $CLASS->all_procs;
is( @get, 4, "4 children" );
is_deeply( \@get, \@all, "Exact list" );

is_deeply(
    [ $CLASS->all_proc_pids ],
    [ map { $_->pid } @all ],
    "pids"
);

is( $_->exit(), undef, "Not waited " . $_->pid ) for @all;
$CLASS->wait_all();
ok( defined($_->exit()), "waited " . $_->pid ) for @all;

done_testing;
