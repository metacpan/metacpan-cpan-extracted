#!/usr/bin/env perl

use warnings;
use strict;

use lib './';

use Test::More;
use API::MikroTik::Sentence qw(encode_sentence);

my $s = API::MikroTik::Sentence->new();

# length encoding
my ($packed, $len);
for (0x7f, 0x3fff, 0x1fffff, 0xfffffff, 0x10000000) {
    $packed = API::MikroTik::Sentence::_encode_length($_);
    ($len, undef) = API::MikroTik::Sentence::_strip_length(\$packed);
    is $len, $_, "length encoding: $_";
}

# encode word
my $encoded = API::MikroTik::Sentence::_encode_word('bla' x 3);
$encoded .= API::MikroTik::Sentence::_encode_word('bla' x 50);
is length($encoded), 162, 'right length';
is $s->_fetch_word(\$encoded), 'bla' x 3, 'right decoded word';
is length($encoded), 152, 'right length';
is $s->_fetch_word(\$encoded), 'bla' x 50, 'right decoded word';

$packed = encode_sentence('/cmd/1', {a => 1, b => 2});
$packed
    .= encode_sentence('/cmd/2', {c => 'foo', d => 'bar'}, {e => 'baz'}, 11);
my $words = $s->fetch(\$packed);
is shift @$words, '/cmd/1', 'right command';
is_deeply [sort @$words], ['=a=1', '=b=2'], 'right attributes';
$words = $s->fetch(\$packed);
is shift @$words, '/cmd/2', 'right command';
is_deeply [sort @$words], ['.tag=11', '=c=foo', '=d=bar', '?e=baz'],
    'right attributes';

# buffer ends in the middle of a word
$packed = encode_sentence('/one/two/three', {test => 1, another => 2});
substr $packed, 20, 20, '';
$words = $s->fetch(\$packed);
is_deeply $words, ['/one/two/three'], 'right results';
ok $s->is_incomplete, 'incomplete is set';

# reset
$s->reset;
ok !$s->is_incomplete, 'incomplete is not longer set';

# buffer ends at the end of the word, before an empty closing word
$packed = encode_sentence('/one/two', {three => 'four'});
my $tr = substr $packed, -1, 1, '';
is $tr, "\0", 'trailing empty word';
$words = $s->fetch(\$packed);
is_deeply $words, ['/one/two', '=three=four'], 'right results';
ok $s->is_incomplete, 'incomplete is set';

my $err;
$SIG{__WARN__} = sub { $err = $_[0] };
$packed = encode_sentence('/cmd', {argv => undef});
ok !$err, 'no warning';
$words = $s->reset->fetch(\$packed);
is_deeply $words, ['/cmd', '=argv='], 'right results';

done_testing();

