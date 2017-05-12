#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(blib/lib ../blib/lib blib/arch ../blib/arch);

use Test::More tests    => 8;
use Encode qw(decode encode);
use Data::Dumper;

BEGIN {
    my $builder = Test::More->builder;
    use_ok 'Data::StreamSerializer';
    $| = 1;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Useqq = 1;
    $Data::Dumper::Deepcopy = 1;
}


my $sr = new Data::StreamSerializer;
ok !defined($sr->next), "Serialize empty object";

$sr = new Data::StreamSerializer [];
ok $sr->next eq '[]', "Serialize empty ARRAY";
ok !defined($sr->next), "Serialized empty ARRAY";

$sr = new Data::StreamSerializer {};
ok $sr->next eq '{}', "Serialize empty HASH";
ok !defined($sr->next), "Serialized empty HASH";

$sr = new Data::StreamSerializer undef;
ok $sr->next eq 'undef', "Serialize undef";
ok !defined($sr->next), "Serialized undef";
