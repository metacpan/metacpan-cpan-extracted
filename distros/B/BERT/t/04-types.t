#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;
use BERT;

# atom
my $atom = BERT::Atom->new('foo');
is($atom, 'foo');
is(length($atom), 3);
is($atom->value, 'foo');

# tuple
my $tuple = BERT::Tuple->new(['foo', 'bar', 'baz']);
is_deeply($tuple->value, ['foo', 'bar', 'baz']);

# boolean
ok(BERT::Boolean->true);
ok(!BERT::Boolean->false);
my $true = BERT::Boolean->true;
my $false = BERT::Boolean->false;
ok($true && !$false);
cmp_ok($true, '==', 1);
cmp_ok($false, '==', 0);
$true = BERT::Boolean->new(1);
$false = BERT::Boolean->new('');
is($true->value, 1);
is($false->value, 0);

# time
my $time = BERT::Time->new(255295581, 446228);
is($time, '255295581.446228');
is_deeply([$time->value], [255295581, 446228]);
    
# dict
my $dict = BERT::Dict->new([ BERT::Atom->new('key') => 'value' ]);
is_deeply($dict->value, [ BERT::Atom->new('key') => 'value' ]);
