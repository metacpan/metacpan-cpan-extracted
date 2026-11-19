use strict;
use warnings;
use Test::More;
use ClickHouse::Encoder;

my $enc = ClickHouse::Encoder->new(columns => [[a => 'UInt32'], [b => 'String'], [c => 'UInt8']]);
my @rows = map { my @r = ('unused') x 12; @r[7, 2, 11] = ($_, "v$_", $_ + 1); \@r } 1 .. 4;
my $expected = $enc->encode([map { [$_->[7], $_->[2], $_->[11]] } @rows]);
my $got = eval { $enc->encode(\@rows, positions => [7, 2, 11]) };
is($@, '', 'projection accepted');
is($got, $expected, 'projection bytes');
my $target = 'prefix';
eval { $enc->encode_into(\$target, \@rows, positions => [7, 2, 11]) };
is($@, '', 'encode_into accepts projection');
is($target, 'prefix' . $expected, 'encode_into appends projected bytes');
my $handle_bytes = '';
open my $fh, '>', \$handle_bytes or die $!;
eval { $enc->encode_to_handle($fh, \@rows, positions => [7, 2, 11]) };
is($@, '', 'encode_to_handle accepts projection');
close $fh;
is($handle_bytes, $expected, 'handle gets projected bytes');
for my $bad (undef, {}, [1, 2], [1, 2, -1], [1, 2, 1.5], [1, 2, 'x'], [1, 2, '1e2'], [1, 2, '99999999999999999999999']) {
    eval { $enc->encode([], positions => $bad) };
    like($@, qr/positions/, 'invalid positions rejected for empty batch');
}
my $nullable = ClickHouse::Encoder->new(columns => [[v => 'Nullable(UInt8)'], [s => 'String']]);
$got = eval { $nullable->encode([[], []], positions => [7, 2]) };
is($@, '', 'short projected rows accepted');
is($got, $nullable->encode([[undef, undef], [undef, undef]]), 'positions beyond row read as undef');
my $defaults = ClickHouse::Encoder->new(columns => [[n => 'UInt8'], [a => 'Array(UInt8)']], defaults => {n => 7});
$got = eval { $defaults->encode([[]], positions => [99, 88]) };
is($@, '', 'short projected row applies defaults and container coercion');
is($got, $defaults->encode([[7, []]]), 'missing positions use column defaults');
$got = eval { $enc->encode([[1, 'v', 1]], positions => [0, 1, 0]) };
is($got, $enc->encode([[1, 'v', 1]]), 'duplicate positions supported');

{
    package CHE::TiedArray;
    sub TIEARRAY { bless [@_[1 .. $#_]], $_[0] }
    sub FETCH { $_[0][$_[1]] }
    sub FETCHSIZE { scalar @{$_[0]} }
}
tie my @inner, 'CHE::TiedArray', (0 .. 39);
tie my @outer, 'CHE::TiedArray', \@inner;
my $wide = ClickHouse::Encoder->new(columns => [map { ["c$_", 'UInt32'] } 0 .. 32]);
my @positions = reverse 0 .. 32;
$got = eval { $wide->encode(\@outer, positions => \@positions) };
is($@, '', 'tied projection spans gather groups');
is($got, $wide->encode([[reverse 0 .. 32]]), 'tied fetch values survive grouped gather');
my @sparse;
$sparse[39] = 'end';
my $strings = ClickHouse::Encoder->new(columns => [[v => 'String'], [w => 'String']]);
$got = eval { $strings->encode([\@sparse], positions => [8, 39]) };
is($got, $strings->encode([['', 'end']]), 'holes in ordinary arrays retain undef coercion');
{
    package CHE::TiedPastEnd;
    sub TIEARRAY { bless [], $_[0] }
    sub FETCHSIZE { 0 }
    sub FETCH { 'past end' }
}
tie my @short, 'CHE::TiedPastEnd';
$got = eval { $strings->encode([\@short], positions => [0, 99]) };
is($@, '', 'tied short rows accepted');
is($got, $strings->encode([[undef, undef]]), 'past-end positions do not call tied FETCH');

done_testing;
