package Acme::AjiFry::EN;

use warnings;
use strict;
use utf8;
use Encode;

use constant MAP => {
    a => '食え食え食え',
    b => '食えドボドボ',
    c => '食えお刺身',
    d => '食えむむ･･･',
    e => '食えアジフライ',
    f => 'フライ食え食え',
    g => 'フライドボドボ',
    h => 'フライお刺身',
    i => 'フライむむ･･･',
    j => 'フライアジフライ',
    k => 'お刺身食え食え',
    l => 'お刺身ドボドボ',
    m => 'お刺身お刺身',
    n => 'お刺身むむ･･･',
    o => 'お刺身アジフライ',
    p => 'アジ食え食え',
    q => 'アジドボドボ',
    r => 'アジお刺身',
    s => 'アジむむ･･･',
    t => 'アジアジフライ',
    u => 'ドボ食え食え',
    v => 'ドボドボドボ',
    w => 'ドボお刺身',
    x => 'ドボむむ･･･',
    y => 'ドボアジフライ',
    z => '山岡食え食え',
    A => '山岡ドボドボ',
    B => '山岡お刺身',
    C => '山岡むむ･･･',
    D => '山岡アジフライ',
    E => '岡星食え食え',
    F => '岡星ドボドボ',
    G => '岡星お刺身',
    H => '岡星むむ･･･',
    I => '岡星アジフライ',
    J => 'ゴク･･･食え食え',
    K => 'ゴク･･･ドボドボ',
    L => 'ゴク･･･お刺身',
    M => 'ゴク･･･むむ･･･',
    N => 'ゴク･･･アジフライ',
    O => 'ああ食え食え',
    P => 'ああドボドボ',
    Q => 'ああお刺身',
    R => 'ああむむ･･･',
    S => 'ああアジフライ',
    T => '雄山食え食え',
    U => '雄山ドボドボ',
    V => '雄山お刺身',
    W => '雄山むむ･･･',
    X => '雄山アジフライ',
    Y => '京極食え食え',
    Z => '京極ドボドボ',

    0 => '京極お刺身',
    1 => '京極むむ･･･',
    2 => '京極アジフライ',
    3 => '陶人食え食え',
    4 => '陶人ドボドボ',
    5 => '陶人お刺身',
    6 => '陶人むむ･･･',
    7 => '陶人アジフライ',
    8 => '社主食え食え',
    9 => '社主ドボドボ',

    space => '中川',
};

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

sub to_English {
    my ( $self, $ajifry_word ) = @_;
    my $chomped = chomp($ajifry_word);

    unless ($ajifry_word) {
        return "\n" if $chomped;
        return '';
    }

    $ajifry_word = Encode::decode_utf8($ajifry_word);
    my $translated_word = $self->_to_English($ajifry_word);
    $translated_word .= "\n" if $chomped;
    return encode_utf8($translated_word);
}

sub translate_from_ajifry {
    my ( $self, $ajifry_word ) = @_;
    return $self->to_English($ajifry_word);
}

sub _to_ajifry {
    my $self       = shift;
    my $raw_string = shift;

    my @raw_chars = split //, $raw_string;
    my $ajifry_word;
    foreach my $raw_char (@raw_chars) {
        if ( $raw_char eq ' ' ) {
            $ajifry_word .= MAP->{space};
        }
        elsif ( $raw_char =~ /[a-zA-Z0-9]/ ) {
            $ajifry_word .= MAP->{$raw_char};
        }
        else {
            $ajifry_word .= $raw_char;
        }
    }

    return $ajifry_word;
}

sub _to_English {
    my $self        = shift;
    my $ajifry_word = shift;

    my $translated_word;
    while ($ajifry_word) {
        my $match = 0;

        my $map = MAP;
        foreach my $key ( keys %{$map} ) {
            if ( $ajifry_word =~ s/^$map->{$key}// ) {
                $match = 1;
                if ( $key eq 'space' ) {
                    $translated_word .= ' ';
                }
                else {
                    $translated_word .= $key;
                }
                last;
            }
        }

        unless ($match) {
            $ajifry_word =~ s/^(.)//;
            $translated_word .= $1;
        }
    }

    return $translated_word;
}
1;

__END__

=encoding utf8

=head1 NAME

Acme::AjiFry::EN - AjiFry Language Translator for English


=head1 SYNOPSIS

    use Acme::AjiFry::EN;

    my $ajifry_en = Acme::AjiFry::EN->new();

    print $ajifry_en->to_AjiFry('012abcABC!!!')."\n"; # outputs => '京極お刺身京極むむ･･･京極アジフライ食え食え食え食えドボドボ食えお刺身山岡ドボドボ山岡お刺身山岡むむ･･･!!!'
    print $ajifry_en->to_English('京極お刺身京極むむ･･･京極アジフライ食え食え食え食えドボドボ食えお刺身山岡ドボドボ山岡お刺身山岡むむ･･･!!!')."\n"; # outputs => '012abcABC!!!'


=head1 DESCRIPTION

Acme::AjiFry::EN is the AjiFry-Language translator.
This module can translate English into AjiFry-Language, and vice versa.


=head1 SEE ALSO

L<Acme::AjiFry>.


=head1 METHODS

=over

=item new

new is the constructor of this module.

=item to_English

This function needs a AjiFry-Language string as parameter.
It returns English which was translated from AjiFry-Language.

=item to_AjiFry

This function needs a string as parameter.
It returns AjiFry-Language which was translated from English.

=back


=head1 AUTHOR

moznion  C<< <moznion[at]gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, moznion C<< <moznion[at]gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
