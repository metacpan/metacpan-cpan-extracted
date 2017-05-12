package Acme::MotorcycleGang;

use warnings;
use strict;
our $VERSION = '0.0.5';

use utf8;

sub yorosiku {
  my $class   = shift if $_[0] eq __PACKAGE__; ## no critic
  my $text    = shift || "";


  local $_ = $text;

  s/あいらぶゆう|あいらぶゆー|アイラブユウ|アイラブユー/愛羅武勇/g;
  s/あいしてる/愛死天流/g;
  s/ありがとう/阿離我妬/g;
  s/いのち/魂/g;
  s/おまわり/悪魔輪離/g;
  s/かっとび/喝斗毘/g;
  s/きまぐれ/鬼魔愚零/g;
  s/きもんど/鬼門怒/g;
  s/しゃこたん/車高短/g;
  s/ぜんと/全塗/g;
  s/だいすき/陀異守鬼/g;
  s/でっぱつ/出発/g;
  s/どらえもん/怒羅衛門/g;
  s/ぶっちぎり/仏恥義理/g;
  s/まくどなるど/魔苦怒奈流怒/g;
  s/まじ/本気/g;
  s/まぶだち/摩武駄致/g;
  s/そうしそうあい/走死走愛/g;
  s/よろしく/夜露死苦/g;
  s/れっさ/烈怒鮫/g;

  s/あい/愛/g;

  # 23 districts in Tokyo
  s/いたばし/威汰罵紫/g;
  s/きた/鬼多/g;
  s/ねりま/根離魔/g;
  s/としま/斗指魔/g;
  s/あだち/亞駄痴/g;
  s/あらかわ/悪裸迦倭/g;
  s/すみだ/酢巳駄/g;
  s/こうとう/抗闘/g;
  s/かつしか/喝紫迦/g;
  s/えどがわ/獲怒我倭/g;
  s/しぶや/士武矢/g;
  s/めぐろ/女愚炉/g;
  s/せたがや/背汰我屋/g;
  s/みなと/魅那斗/g;
  s/しながわ/紫那我倭/g;
  s/おおた/皇汰/g;
  s/なかの/那迦乃/g;
  s/すぎなみ/酢魏那魅/g;
  s/ぶんきょう/聞狂/g;
  s/しんじゅく/神呪苦/g;
  s/たいとう/隊闘/g;
  s/ちゅうおう/忠皇/g;
  s/ちよだ/恥酔駄/g;


  $_;
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::MotorcycleGang - Translate Japanese MotorcycleGang Language


=head1 VERSION

This document describes Acme::MotorcycleGang version 0.0.5


=head1 SYNOPSIS

    use Acme::MotorcycleGang;
    Acme::MotorcycleGang->yorosiku("よろしく！");  # returnd 夜露死苦！

=head1 FUNCTIONS

=head2 yorosiku

    this module is this function only.
    input japanese Language, output Japanese MotorcycleGang language
 
=head1 DESCRIPTION

This module is My First Module.
please tell me if i wrong.


=head1 AUTHOR

yuichi tsunoda  C<< <yuichi.tsunoda@gmail.com> >>


=head1 LICENCE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


