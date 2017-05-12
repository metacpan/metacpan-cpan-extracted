#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(blib/lib blib/arch);

use Test::More tests    => 3;
use Encode qw(decode encode);


BEGIN {
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'Data::StreamDeserializer';
}

my $dsr = new Data::StreamDeserializer
    data => q!qr#^(?>.+)(??{ join ", ", 1, 2, 3 })abc|def$#!;

my @objects;
until($dsr->is_done) {
    1 until $dsr->next_object;
}

diag $dsr->error unless ok !$dsr->is_error, "Regexp was parsed";
ok 'Regexp' eq ref $dsr->result, "Regexp was parsed properly";
