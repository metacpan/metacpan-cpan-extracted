use 5.010;
use strict;
use warnings;
use Test::More 0.96;
binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use Data::Visitor::Tiny qw/visit/;

my $array = [ 1 .. 10 ];

my $hash = { map { $_ => ord($_) } 'a' .. 'j' };

my $deep = {
    larry => {
        color   => 'red',
        fruit   => 'apple',
        friends => [ { name => 'Moe' }, { name => 'Curly' } ],
    },
    moe => {
        color   => 'yellow',
        fruit   => 'banana',
        friends => [ { name => 'Curly' } ],
    },
    curly => {
        color   => 'purple',
        fruit   => 'plum',
        friends => [ { name => 'Larry', nickname => 'Lray' } ],
    },
};

my @deep_leaves = qw(
  red apple Moe Curly yellow banana Curly purple plum Larry Lray
);

subtest "Visit arrayref" => sub {
    my @values;
    visit( $array, sub { push @values, $_ } );
    is_deeply( \@values, [ 1 .. 10 ], "visting saw all values in \$_" );

};

subtest "Visit hashref" => sub {
    my @values;
    visit( $hash, sub { push @values, $_ } );
    is_deeply(
        [ sort { $a <=> $b } @values ],
        [ ord('a') .. ord('j') ],
        "visting saw all values in \$_"
    );
};

subtest "Visit deep" => sub {
    my @values;
    my %count;
    visit(
        $deep,
        sub {
            if (ref) {
                $count{ ref($_) }++;
            }
            else {
                push @values, $_;
            }
        }
    );
    is( $count{ARRAY}, 3, "Saw 3 arrayrefs" );
    is( $count{HASH},  7, "Saw 7 hashrefs" );
    is_deeply( [ sort @values ], [ sort @deep_leaves ],
        "visting saw all values in \$_" );
};

done_testing;

#
# This file is part of Data-Visitor-Tiny
#
# This software is Copyright (c) 2018 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: set ts=4 sts=4 sw=4 et tw=75:
