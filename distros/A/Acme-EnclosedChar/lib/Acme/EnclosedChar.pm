package Acme::EnclosedChar;
use strict;
use warnings;
use utf8;
use parent qw/Exporter/;
our @EXPORT_OK = qw/
    enclose
    enclose_katakana
    enclose_week_ja
    enclose_kansuji
    enclose_kanji
    enclose_all
/;

our $VERSION = '0.09';

my %MAP;
{
    my @double_digits = split('', '⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲'
                                . '⑳㉑㉒㉓㉔㉕㉖㉗㉘㉙'
                                . '㉚㉛㉜㉝㉞㉟㊱㊲㊳㊴'
                                . '㊵㊶㊷㊸㊹㊺㊻㊼㊽㊾㊿');
    for my $i (10..50) {
        $MAP{double_digits}->{$i} = shift @double_digits;
    }
}

sub _tr_double_digits {
    for my $dg (keys %{$MAP{double_digits}}) {
        ${$_[0]} =~ s!(^|[^\d])$dg([^\d]|$)!$1$MAP{double_digits}->{$dg}$2!g;
    }
}

sub _tr_numbers {
    ${$_[0]} =~ tr/0123456789/⓪①②③④⑤⑥⑦⑧⑨/;
}

sub _tr_alphabet_uc {
    ${$_[0]} =~ tr/ABCDEFGHIJKLMNOPQRSTUVWXYZ/ⒶⒷⒸⒹⒺⒻⒼⒽⒾⒿⓀⓁⓂⓃⓄⓅⓆⓇⓈⓉⓊⓋⓌⓍⓎⓏ/;
}

sub _tr_alphabet_lc {
    ${$_[0]} =~ tr/abcdefghijklmnopqrstuvwxyz/ⓐⓑⓒⓓⓔⓕⓖⓗⓘⓙⓚⓛⓜⓝⓞⓟⓠⓡⓢⓣⓤⓥⓦⓧⓨⓩ/;
}

sub _tr_symbols {
    ${$_[0]} =~ tr/\-\=\+\*/⊖⊜⊕⊛/;
}

sub _tr_katakana {
    ${$_[0]} =~ tr/アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヰヱヲ/㋐㋑㋒㋓㋔㋕㋖㋗㋘㋙㋚㋛㋜㋝㋞㋟㋠㋡㋢㋣㋤㋥㋦㋧㋨㋩㋪㋫㋬㋭㋮㋯㋰㋱㋲㋳㋴㋵㋶㋷㋸㋹㋺㋻㋼㋽㋾/;
}

sub _tr_week_ja {
    ${$_[0]} =~ tr/月火水木金土日/㊊㊋㊌㊍㊎㊏㊐/;
}

sub _tr_kansuji {
    ${$_[0]} =~ tr/一二三四五六七八九十/㊀㊁㊂㊃㊄㊅㊆㊇㊈㊉/;
}

sub _tr_kanji {
    ${$_[0]} =~ tr/株有社名特財祝労秘男女適優印注頂休写正上中下左右医宗学監企資協夜/㊑㊒㊓㊔㊕㊖㊗㊘㊙㊚㊛㊜㊝㊞㊟㊠㊡㊢㊣㊤㊥㊦㊧㊨㊩㊪㊫㊬㊭㊮㊯㊰/;
}

sub enclose {
    my $string = shift;

    return '' if !defined($string) || $string eq '';

    _tr_double_digits(\$string);
    _tr_numbers(\$string);
    _tr_alphabet_uc(\$string);
    _tr_alphabet_lc(\$string);
    _tr_symbols(\$string);

    return $string;
}

sub enclose_katakana {
    my $string = shift;

    $string = enclose($string);
    _tr_katakana(\$string);

    return $string;
}

sub enclose_week_ja {
    my $string = shift;

    $string = enclose($string);
    _tr_week_ja(\$string);

    return $string;
}

sub enclose_kansuji {
    my $string = shift;

    $string = enclose($string);
    _tr_kansuji(\$string);

    return $string;
}

sub enclose_kanji {
    my $string = shift;

    $string = enclose($string);
    _tr_kanji(\$string);

    return $string;
}

sub enclose_all {
    my $string = shift;

    return enclose_katakana(
            enclose_week_ja( enclose_kansuji( enclose_kanji($string) ) )
    );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Acme::EnclosedChar - Ⓔⓝⓒⓛⓞⓢⓔⓓ Ⓐⓛⓟⓗⓐⓝⓤⓜⓔⓡⓘⓒⓢ Ⓔⓝⓒⓞⓓⓔⓡ


=head1 SYNOPSIS

    use Acme::EnclosedChar qw/enclose/;

    print enclose('Perl'); # Ⓟⓔⓡⓛ


=head1 DESCRIPTION

Acme::EnclosedChar generates Enclosed Alphanumerics.


=head1 METHOD

=head2 enclose($decoded_text)

encode text into Enclosed Alphanumerics

=head2 enclose_katakana($decoded_text)

Also Japanese Katakana will be encoded.

=head2 enclose_week_ja($decoded_text)

Also Japanese day of week will be encoded.

=head2 enclose_kansuji($decoded_text)

Also Japanese kansuji will be encoded.

=head2 enclose_kanji($decoded_text)

Also Japanese kanji will be encoded.

=head2 enclose_all($decoded_text)

enclose text as far as possible


=head1 REPOSITORY

Acme::EnclosedChar is hosted on github: L<http://github.com/bayashi/Acme-EnclosedChar>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<http://www.unicode.org/>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
