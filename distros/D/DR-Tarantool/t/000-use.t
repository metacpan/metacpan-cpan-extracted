#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

use Test::More tests    => 10;
use Encode qw(decode encode);


BEGIN {
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";


    use_ok 'DR::Tarantool';
    use_ok 'DR::Tarantool';
    use_ok 'DR::Tarantool', ':all';
    use_ok 'DR::Tarantool', ':constant';
    use_ok 'DR::Tarantool::AsyncClient';
    use_ok 'DR::Tarantool::LLClient';
    use_ok 'DR::Tarantool::Spaces';
    use_ok 'DR::Tarantool::StartTest';
    use_ok 'DR::Tarantool::SyncClient';
    use_ok 'DR::Tarantool::Tuple';
}
