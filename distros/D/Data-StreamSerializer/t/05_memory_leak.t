#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 3;
use Time::HiRes qw(time);
use Encode qw(decode encode);
use Sys::Hostname;

use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'Data::StreamSerializer';
}

sub gen_rand_object() {
    my $h = {};
    for (0 .. 20) {
        for (0 .. 20) {
            $h->{rand()} = [ map { rand } 0 .. 10 ];
        }
    }

    $h;
}

my $size_start = Data::StreamSerializer::_memory_size;

my $size = Data::StreamSerializer::_memory_size;
my $size_end = Data::StreamSerializer::_memory_size;
my $time = time;
my $count = 0;
my $i = 0;
my $len = 0;
for(;;) {
    my $sr = new Data::StreamSerializer(gen_rand_object);
    while (defined (my $part = $sr->next)) {
        $len += length $part;
        $i++;
    }

    if ($count++ < 20) {
        $size = Data::StreamSerializer::_memory_size;
    } elsif($count++ < 100) {
        $size_end = Data::StreamSerializer::_memory_size;
        last unless $size_end <= $size;
    } else {
        last;
    }
}

my $leak = $size_end - $size;
ok $size_end <= $size, "Check memory leak ($leak bytes)";
note "$i iterations were done, $len bytes were produced";


if (Data::StreamSerializer::_memory_size > $size_start) {
    ok 1, "Check memory checker";
} elsif (hostname =~ /^(apache|marish|nbw)$/) {
    fail "Check memory checker";
} else {
    ok 1, "Check memory checker: Failed"; # BSD and darwin
    diag "sbrk returns value: " . Data::StreamSerializer::_memory_size;
}
