#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(blib/lib blib/arch);

use Test::More tests    => 5;
use Encode qw(decode encode);


BEGIN {
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'Data::StreamDeserializer';
}


my $str = q^
    { "a" => "b", "a" => { "c" => 'd'} }
^;

my $dsr = new Data::StreamDeserializer data => $str;
1 until $dsr->next;

my $res = $dsr->result;
ok 1 == keys %$res, "Hash parsed properly";
ok $res->{a}{c} eq 'd', "Last value overlaps the first";

$str = q^
    { "a" => [ 1, 3, 4 ], "a" => { "c" => "d" } }
^;

$dsr = new Data::StreamDeserializer data => $str;
1 until $dsr->next;

$res = $dsr->result;
ok 1 == keys %$res, "Hash parsed properly";
ok $res->{a}{c} eq 'd', "Last value overlaps the first";
