#! /usr/bin/perl
# $Id: 05_leak.t,v 1.1.1.1 2007/04/11 15:15:54 dk Exp $

use strict;
use warnings;

use Test::More;

eval 'use Devel::Leak';
plan skip_all => 'Devel::Leak required for testing memory leaks'
    if $@;

use Array::Slice qw(:all);

sub is_leakproof (&;$) {
    my ($code, $action) = @_;
    my $handle;
    my $count = Devel::Leak::NoteSV($handle);
    $code->();
    my $new_count = Devel::Leak::CheckSV($handle);
    ok( $new_count == $count, $action);
}

plan tests => 2;

my @g = 1..1000;
slice @g, 1; # create iterator and stash entry

reset @g;
is_leakproof { do {} while ( my @g          = slice @g, 10) } 'explicit slicing';

reset @g;
is_leakproof { do {} while ( my ($a,$b,$c)  = slice @g) }     'implicit slicing';

