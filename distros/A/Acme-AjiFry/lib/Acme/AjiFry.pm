package Acme::AjiFry;

use warnings;
use strict;
use utf8;
use Encode;
use List::Util;

our $VERSION = '0.09';

use constant COLS => {
    a => [
        'あ', 'か', 'さ', 'た', 'な', 'は', 'ま', 'や', 'ら', 'わ',
        'が', 'ざ', 'だ', 'ば', 'ぱ', 'ぁ', 'ゃ', 'ゎ'
    ],
    i => [
        'い', 'き', 'し', 'ち', 'に', 'ひ', 'み', 'り',
        'ぎ', 'じ', 'ぢ', 'び', 'ぴ', 'ぃ'
    ],
    u => [
        'う', 'く', 'す', 'つ', 'ぬ', 'ふ', 'む', 'ゆ', 'る', 'ぐ',
        'ず', 'づ', 'ぶ', 'ぷ', 'ぅ', 'っ', 'ゅ'
    ],
    e => [
        'え', 'け', 'せ', 'て', 'ね', 'へ', 'め', 'れ',
        'げ', 'ぜ', 'で', 'べ', 'ぺ', 'ぇ',
    ],
    o => [
        'お', 'こ', 'そ', 'と', 'の', 'ほ', 'も', 'よ', 'ろ', 'を',
        'ご', 'ぞ', 'ど', 'ぼ', 'ぽ', 'ぉ', 'ょ'
    ],
    n => ['ん'],
};
use constant ROWS => {
    a =>
      [ 'あ', 'い', 'う', 'え', 'お', 'ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ' ],
    k =>
      [ 'か', 'き', 'く', 'け', 'こ', 'が', 'ぎ', 'ぐ', 'げ', 'ご' ],
    s =>
      [ 'さ', 'し', 'す', 'せ', 'そ', 'ざ', 'じ', 'ず', 'ぜ', 'ぞ' ],
    t => [
        'た', 'ち', 'つ', 'て', 'と', 'だ',
        'ぢ', 'づ', 'で', 'ど', 'っ'
    ],
    n => [ 'な', 'に', 'ぬ', 'ね', 'の' ],
    h => [
        'は', 'ひ', 'ふ', 'へ', 'ほ', 'ば', 'び', 'ぶ',
        'べ', 'ぼ', 'ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ'
    ],
    m => [ 'ま', 'み', 'む', 'め', 'も' ],
    y => [ 'や', 'ゆ', 'よ', 'ゃ', 'ゅ', 'ょ' ],
    r => [ 'ら', 'り', 'る', 'れ', 'ろ' ],
    w => [ 'わ', 'を', 'ゎ' ],
};
use constant DULLNESS => [
    'が', 'ぎ', 'ぐ', 'げ', 'ご', 'ざ', 'じ', 'ず', 'ぜ', 'ぞ',
    'だ', 'ぢ', 'づ', 'で', 'ど', 'ば', 'び', 'ぶ', 'べ', 'ぼ'
];
use constant P_SOUND => [ 'ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ' ];
use constant DOUBLE_CONSONANT =>
  [ 'ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ', 'っ', 'ゃ', 'ゅ', 'ょ', 'ゎ' ];

sub new {
    my $class = shift;
    return $class;
}

sub to_AjiFry {
    my ( $self, $raw_string ) = @_;

    my $chomped = chomp($raw_string);
    unless ($raw_string) {
        return "\n" if $chomped;
        return '';
    }

    $raw_string = decode_utf8($raw_string);
    my $ajifry_word = $self->_to_ajifry($raw_string);
    $ajifry_word .= "\n" if $chomped;
    return encode_utf8($ajifry_word);
}

sub translate_to_ajifry {
    my ( $self, $raw_string ) = @_;
    return $self->to_AjiFry($raw_string);
}

sub to_Japanese {
    my ( $self, $ajifry_word ) = @_;
    my $chomped = chomp($ajifry_word);

    unless ($ajifry_word) {
        return "\n" if $chomped;
        return '';
    }

    $ajifry_word = decode_utf8($ajifry_word);
    my $japanese_word = $self->_to_Japanese($ajifry_word);
    $japanese_word .= "\n" if $chomped;
    return encode_utf8($japanese_word);
}

sub translate_from_ajifry {
    my ( $self, $ajifry_word ) = @_;
    return $self->to_Japanese($ajifry_word);
}

sub _search_key_of_element {
    my ( $self, $element, $hash ) = @_;

    foreach my $key ( sort keys %$hash ) {
        if ( List::Util::first { $_ eq $element } @{ $hash->{$key} } ) {
            return $key;
        }
    }
}

sub _find_first {
    my ( $self, $key, $list ) = @_;

    return ( List::Util::first { $_ eq $key } @$list ) ? 1 : 0;
}

sub _find_duplicate_element_in_both_lists {
    my $self = shift;
    my ( $list_A, $list_B ) = @_;

    my @duplicate_elements;
    foreach my $element_A ( @{$list_A} ) {
        foreach my $element_B ( @{$list_B} ) {
            if ( $element_A eq $element_B ) {
                push( @duplicate_elements, $element_A );
            }
        }
    }
    return @duplicate_elements;
}

sub _get_ajifry_word_by_consonant {
    my $self      = shift;
    my $consonant = shift;

    if ( $consonant eq 'a' ) {
        return "食え";
    }
    elsif ( $consonant eq 'k' ) {
        return "フライ";
    }
    elsif ( $consonant eq 's' ) {
        return "お刺身";
    }
    elsif ( $consonant eq 't' ) {
        return "アジ";
    }
    elsif ( $consonant eq 'n' ) {
        return "ドボ";
    }
    elsif ( $consonant eq 'h' ) {
        return "山岡";
    }
    elsif ( $consonant eq 'm' ) {
        return "岡星";
    }
    elsif ( $consonant eq 'y' ) {
        return "ゴク･･･";
    }
    elsif ( $consonant eq 'r' ) {
        return "ああ";
    }
    elsif ( $consonant eq 'w' ) {
        return "雄山";
    }
    else {
        return "";
    }
}

sub _get_ajifry_word_by_vowel {
    my $self  = shift;
    my $vowel = shift;

    if ( $vowel eq 'a' ) {
        return "食え食え";
    }
    elsif ( $vowel eq 'i' ) {
        return "ドボドボ";
    }
    elsif ( $vowel eq 'u' ) {
        return "お刺身";
    }
    elsif ( $vowel eq 'e' ) {
        return "むむ･･･";
    }
    elsif ( $vowel eq 'o' ) {
        return "アジフライ";
    }
    elsif ( $vowel eq 'n' ) {
        return "京極";
    }
    else {
        return "";
    }
}

sub _get_consonant_by_ajifry_word {
    my $self        = shift;
    my $ajifry_word = shift;

    if ( $ajifry_word eq '食え' ) {
        return 'a';
    }
    elsif ( $ajifry_word eq 'フライ' ) {
        return 'k';
    }
    elsif ( $ajifry_word eq 'お刺身' ) {
        return 's';
    }
    elsif ( $ajifry_word eq 'アジ' ) {
        return 't';
    }
    elsif ( $ajifry_word eq 'ドボ' ) {
        return 'n';
    }
    elsif ( $ajifry_word eq '山岡' ) {
        return 'h';
    }
    elsif ( $ajifry_word eq '岡星' ) {
        return 'm';
    }
    elsif ($ajifry_word eq 'ゴク・・・'
        || $ajifry_word eq 'ゴク･･･'
        || $ajifry_word eq 'ゴク…' )
    {
        return 'y';
    }
    elsif ( $ajifry_word eq 'ああ' ) {
        return 'r';
    }
    elsif ( $ajifry_word eq '雄山' ) {
        return 'w';
    }
    else {
        return;
    }
}

sub _get_vowel_by_ajifry_word {
    my $self        = shift;
    my $ajifry_word = shift;

    if ( $ajifry_word eq '食え食え' ) {
        return 'a';
    }
    elsif ( $ajifry_word eq 'ドボドボ' ) {
        return 'i';
    }
    elsif ( $ajifry_word eq 'お刺身' ) {
        return 'u';
    }
    elsif ($ajifry_word eq 'むむ・・・'
        || $ajifry_word eq 'むむ･･･'
        || $ajifry_word eq 'むむ…' )
    {
        return 'e';
    }
    elsif ( $ajifry_word eq 'アジフライ' ) {
        return 'o';
    }
    else {
        return;
    }
}

sub _to_ajifry {
    my $self       = shift;
    my $raw_string = shift;

    my @raw_chars = split //, $raw_string;
    my $ajifry_word;
    foreach my $raw_char (@raw_chars) {
        my $vowel     = $self->_search_key_of_element( $raw_char, COLS );
        my $consonant = $self->_search_key_of_element( $raw_char, ROWS );

        if ( !$vowel && !$consonant ) {
            $ajifry_word .= $raw_char;    # not HIRAGANA
            next;
        }

        $ajifry_word .= "中川"
          if $self->_find_first( $raw_char, DOUBLE_CONSONANT );
        $ajifry_word .= $self->_get_ajifry_word_by_consonant($consonant);
        $ajifry_word .= $self->_get_ajifry_word_by_vowel($vowel);
        $ajifry_word .= "社主" if $self->_find_first( $raw_char, P_SOUND );
        $ajifry_word .= "陶人" if $self->_find_first( $raw_char, DULLNESS );
    }
    return $ajifry_word;
}

sub _to_Japanese {
    my $self        = shift;
    my $ajifry_word = shift;

    my $translated_word;
    while (1) {
        unless ($ajifry_word) {
            last;
        }

        my $is_double_consonant = 0;
        if ( $ajifry_word =~ s/^京極// ) {
            $translated_word .= 'ん';
            next;
        }
        elsif ( $ajifry_word =~ s/^中川// ) {
            $is_double_consonant = 1;
        }

        my $consonant;
        if ( $ajifry_word =~ s/^(食え|フライ|お刺身|アジ|ドボ|山岡|岡星|ゴク・・・|ゴク･･･|ゴク…|ああ|雄山)//
          )
        {
            $consonant = $1;
        }
        unless ($consonant) {
            $ajifry_word =~ s/^(.)//;
            $translated_word .= $1;
            next;
        }
        my $vowel;
        if ( $ajifry_word =~ s/^(食え食え|ドボドボ|お刺身|むむ・・・|むむ･･･|むむ…|アジフライ)//
          )
        {
            $vowel = $1;
        }
        unless ($vowel) {
            $translated_word .= $consonant;
            $ajifry_word =~ s/^(.)//;
            $translated_word .= $1;
            next;
        }

        my $is_dullness;
        $is_dullness = $1 if $ajifry_word =~ s/^(陶人)//;
        my $is_p_sound;
        $is_p_sound = $1 if $ajifry_word =~ s/^(社主)//;

        $consonant = $self->_get_consonant_by_ajifry_word($consonant);
        $vowel     = $self->_get_vowel_by_ajifry_word($vowel);

        my @match_characters =
          $self->_find_duplicate_element_in_both_lists( ROWS->{$consonant},
            COLS->{$vowel} );
        if ($is_p_sound) {
            $translated_word .= $match_characters[2];
        }
        elsif ($is_dullness) {
            $translated_word .= $match_characters[1];
        }
        elsif ( $is_double_consonant && $consonant eq 't' ) {
            $translated_word .= $match_characters[2];
        }
        elsif ($is_double_consonant) {
            $translated_word .= $match_characters[1];
        }
        else {
            $translated_word .= $match_characters[0];
        }
    }

    return $translated_word;
}

1;

__END__

=encoding utf8

=head1 NAME

Acme::AjiFry - AjiFry Language (アジフライ語) Translator


=head1 VERSION

This document describes Acme::AjiFry version 0.09


=head1 SYNOPSIS

    use Acme::AjiFry;

    my $ajifry = Acme::AjiFry->new();

    print $ajifry->to_AjiFry('おさしみ')."\n"; # outputs => "食えアジフライお刺身食え食えお刺身ドボドボ岡星ドボドボ"
    print $ajifry->to_Japanese('食えアジフライお刺身食え食えお刺身ドボドボ岡星ドボドボ')."\n"; # outputs => "おさしみ"


=head1 DESCRIPTION

Acme::AjiFry is the AjiFry-Language translator.
This module can translate Japanese into AjiFry-Language, and vice versa.
If you would like to know about AjiFry-Language, please refer to the following web site (Japanese Web Site).
L<http://ja.uncyclopedia.info/wiki/%E3%82%A2%E3%82%B8%E3%83%95%E3%83%A9%E3%82%A4%E8%AA%9E>

=head1 METHODS

=over

=item new

new is the constructor of this module.

=item to_Japanese

This function needs a AjiFry-Language string as parameter.
It returns Japanese which was translated from AjiFry-Language.

=item to_AjiFry

This function needs a string as parameter.
It returns AjiFry-Language which was translated from Japanese.

=back

=head1 DEPENDENCIES

=over 4

=item * Encode (version 2.39 or later)

=back


=head1 BUGS AND LIMITATIONS

=for author to fill in:
A list of known problems with the module, together with some
indication Whether they are likely to be fixed in an upcoming
release. Also a list of restrictions on the features the module
does provide: data types that cannot be handled, performance issues
and the circumstances in which they may arise, practical
limitations on the size of data sets, special cases that are not
(yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-acme-ajifry@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

moznion  C<< <moznion[at]gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, moznion C<< <moznion[at]gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
