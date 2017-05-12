#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 15;
use Encode qw(decode encode);

use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Msgpuck', 'msgpack', 'msgunpack_check';
    use_ok 'DR::Msgpuck::Str';
    use_ok 'DR::Msgpuck::Num';
    use_ok 'Data::Dumper';
    
    $Data::Dumper::Indent = 0;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Useqq = 1;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Maxdepth = 0;
}


is msgunpack_check undef, 0, 'msgunpack_check undef';


for my $raw (undef, 'a', [ 'a' ], [ a => { b => 'c' } ], { a => 'b', c => [ 1, undef ] }) {
    my $pkt = msgpack $raw;
    is msgunpack_check $pkt, length $pkt, 'lengh for ' . Dumper $raw;
    substr $pkt, -1, 1, '';
    is msgunpack_check $pkt, 0, 'invalid len';
}
