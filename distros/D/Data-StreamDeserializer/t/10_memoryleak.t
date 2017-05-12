#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use lib qw(blib/lib ../blib/lib blib/arch ../blib/arch);
use Test::More tests    => 3;
use Data::Dumper;
use Time::HiRes qw(time);
use Encode qw(decode encode);
use Sys::Hostname;


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Useqq = 1;
    $Data::Dumper::Deepcopy = 1;

    use_ok 'Data::StreamDeserializer';
}


sub gen_rand_object() {
    my $h = {};
    for (0 .. 20) {
        for (0 .. 20) {
            $h->{rand()} = [ map { "aa\\n" . rand } 0 .. 10 ];
        }
    }

    $h;
}

my $size;
my $size_end;
my $counter = 0;
my $i = 0;
my $len = 0;
my $pcount = 0;

my @tests = map { Dumper gen_rand_object  } 0 .. 5;
for(;;)
{
    my $str = $tests[rand @tests];
    my $ds = new Data::StreamDeserializer data => $str;

    $i++ until $ds->next;
    $len+= length $str;
    $pcount++;

    if ($pcount < 30) {
        $size = Data::StreamDeserializer::_memory_size;
    } elsif ($pcount < 100) {
        $size_end = Data::StreamDeserializer::_memory_size;
        last if $size_end != $size;
    } else {
        last;
    }
}

my $leak = $size_end - $size;
ok $size_end == $size, "Check memory leak ($leak bytes)";
note "$pcount/$i iterations/subiterations were done, $len bytes were parsed";

SKIP: {
    skip "This test is only for my system", 1
        if hostname !~ /^(apache|marish|nbw)$/;
    $size = $size_end;
    for (1 .. 20_000_000 + int rand 50_000_000) {
        push @tests, rand rand 1000;
        $size_end = Data::StreamDeserializer::_memory_size;
        last if $size_end != $size;
    }
    ok $size_end != $size,
        sprintf "Check memory checker (size: %d elements) :)", scalar @tests;
}
