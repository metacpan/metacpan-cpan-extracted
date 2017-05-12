#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use open OUT => qw/:utf8 :std/;
use feature     qw/say/;
use Encode      qw//;

my %CP932;
my %SJIS;

my $ENC_CP932 = Encode::find_encoding("CP932");
my $ENC_SJIS  = Encode::find_encoding("Shift_JIS");

for my $dec ( hex('0') .. hex('10FFFF') ) # サロゲート文字を含んでいる
{
    my $point = sprintf("U+%06X", $dec);
    my $char  = chr $dec;

    #say $point;

    $CP932{$point} = $char unless is_gaiji_cp932($char);
    $SJIS{$point}  = $char unless is_gaiji_sjis($char);
}

say "CP932 に変換可能な文字数：" . scalar keys %CP932; # 9485
say "SJIS に変換可能な文字数："  . scalar keys %SJIS;  # 7070

# Unicode の文字のうち、CP932に変換可能 で Shift_JIS に変換可能でない文字を求める
my %CP932_NOT_SJIS;

for my $point (keys %CP932)
{
    if ( ! exists $SJIS{$point} )
    {
        $CP932_NOT_SJIS{$point} = $CP932{$point};
    }
}

say "CP932 に変換可能で Shift_JIS に変換可能でない文字数："  . scalar keys %CP932_NOT_SJIS;

# Unicode の文字のうち、Shift-JIS 変換可能で CP932 に変換可能でない文字を求める
my %SJIS_NOT_CP932;

for my $point (keys %SJIS)
{
    if ( ! exists $CP932{$point} )
    {
        $SJIS_NOT_CP932{$point} = $SJIS{$point}
    }
}

say "Shift_JIS に変換可能で CP932 で変換可能でない文字数：" . scalar keys %SJIS_NOT_CP932;

# Unicode の文字のうち、CP932 かつSJIS は 7067文字。

say "CP932 に変換可能で Shift_JIS に変換可能でない：";
for my $point (sort keys %CP932_NOT_SJIS)
{
    say "$point： $CP932_NOT_SJIS{$point}";
}

say "Shift_JIS に変換可能で CP932 に変換可能でない：";
for my $point (sort keys %SJIS_NOT_CP932)
{
    say "$point： $SJIS_NOT_CP932{$point}";
}

exit;

sub is_gaiji_cp932
{
    my $char = shift;
    eval { $ENC_CP932->encode($char, Encode::FB_CROAK) };
    return 1 if $@;
    return 0;
}

sub is_gaiji_sjis
{
    my $char = shift;
    eval { $ENC_SJIS->encode($char, Encode::FB_CROAK) };
    return 1 if $@;
    return 0;
}
