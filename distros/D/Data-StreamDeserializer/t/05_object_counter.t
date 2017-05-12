#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(blib/lib blib/arch);

use Test::More tests    => 9;
use Encode qw(decode encode);


BEGIN {
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'Data::StreamDeserializer';
}

{
    my $dsr = new Data::StreamDeserializer
        data => q/1, [ 1.23, 2. ], {'a' => .4}, 0.32, 3.2, { 1 => 2 }    aaa /,
        block_size => 2;

    my @objects;
    until($dsr->is_done) {
        1 until $dsr->next_object;
        push @objects, [ $dsr->result, $dsr->tail ] unless $dsr->is_error;
    }

    ok @objects == 6, "All objects were extracted";
    ok $dsr->is_error, "Error has detected properly";
    ok $dsr->tail eq "aaa ", "Tail is correct";
    ok $objects[-1][1] eq '    aaa ', "Last object's tail was correct";
}

{
    my $dsr = new Data::StreamDeserializer
        data => q/1 [ 1.23, 2. ] {'a' => .4} 0.32 343.0 { 1 => 2 }    aaa /,
        block_size => 2;

    my @objects;
    until($dsr->is_done) {
        1 until $dsr->next_object;
        unless($dsr->is_error) {
            push @objects, [ $dsr->result, $dsr->tail ];
            $dsr->skip_divider;
        }
    }

    ok @objects == 6, "All objects were extracted (skip_divider)";
    ok $dsr->is_error, "Error has detected properly (skip_divider)";
    ok $dsr->tail eq "aaa ", "Tail is correct (skip_divider)";
    ok $objects[-1][1] eq '    aaa ',
        "Last object's tail was correct (skip_divider)";
}
