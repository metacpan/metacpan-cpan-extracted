#!/usr/bin/env perl

use warnings;
use strict;

use lib './';

use Test::More;
use API::MikroTik::Response;
use API::MikroTik::Sentence qw(encode_sentence);

my $r = API::MikroTik::Response->new();

my $packed = encode_sentence('!re', {a => 1, b => 2});
$packed .= encode_sentence('!re', {c => 3, d => 4, e => 5}, undef, 3);
$packed .= encode_sentence('!done');

my $data = $r->parse(\$packed);
is_deeply $data,
    [
    {a => '1', b => '2', '.tag' => '',  '.type' => '!re'},
    {e => '5', d => '4', c      => '3', '.tag'  => '3', '.type' => '!re'},
    {'.tag' => '', '.type' => '!done'}
    ],
    'right response';

# reassemble partial buffer
my ($attr, @parts);
$attr->{$_} = $_ x 200 for 1 .. 4;

$packed = encode_sentence('!re', $attr);
$packed .= $packed . $packed . $packed;
push @parts, (substr $packed, 0, $_, '') for (900, 700, 880, 820);

$attr->{'.tag'}  = '';
$attr->{'.type'} = '!re';

my $w = $r->parse(\$parts[0]);
is_deeply $w, [$attr], 'right result';
ok $r->sentence->is_incomplete, 'incomplete is set';
$w = $r->parse(\$parts[1]);
is_deeply $w, [], 'right result';
ok $r->sentence->is_incomplete, 'incomplete is set';
$w = $r->parse(\$parts[2]);
is_deeply $w, [($attr) x 2], 'right result';
ok $r->sentence->is_incomplete, 'incomplete is set';
$w = $r->parse(\$parts[3]);
is_deeply $w, [$attr], 'right result';
ok !$r->sentence->is_incomplete, 'incomplete is not set';

done_testing();

