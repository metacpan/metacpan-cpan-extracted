package Acme::Tategaki;
use 5.008005;
use strict;
use warnings;
use utf8;
use Array::Transpose::Ragged qw/transpose_ragged/;
use Encode qw/encode_utf8 decode_utf8/;
use Data::Dump qw/dump/;

use parent 'Exporter';
our @EXPORT = qw( tategaki tategaki_one_line);

our $VERSION = "0.12";

my @punc = qw(、 。 ， ．);

sub tategaki_one_line {
    my $text = shift;
    return _convert_vertical(($text));

}

sub tategaki {
    my $text = shift;
    $text =~ s/$_\s?/$_　/g for @punc;
    my @text = split /\s/, $text;
    return _convert_vertical(@text);
}

sub _convert_vertical {
    my @text = @_;
    @text = map { [ split //, $_ ] } @text;
    @text = transpose_ragged( \@text );
    @text = map { [ map {$_ || '　' } @$_ ] } @text;
    @text = map { join '　', reverse @$_ } @text;

    for (@text) {
        $_ =~ tr/／‥−－─ー「」→↑←↓＝=,、。〖〗【】…/＼：｜｜｜｜¬∟↓→↑←॥॥︐︑︒︗︘︗︘︙/;
        $_ =~ s/〜/∫ /g;
        $_ =~ s/『/ ┓/g;
        $_ =~ s/』/┗ /g;
        $_ =~ s/［/┌┐/g;
        $_ =~ s/］/└┘/g;
        $_ =~ s/\[/┌┐/g;
        $_ =~ s/\]/└┘/g;
        $_ =~ s/＜/∧ /g;
        $_ =~ s/＞/∨ /g;
        $_ =~ s/</∧ /g;
        $_ =~ s/>/∨ /g;
        $_ =~ s/《/∧ /g;
        $_ =~ s/》/∨ /g;
    }
    # print dump @text;

    return join "\n", @text;
}

if ( __FILE__ eq $0 ) {
    print encode_utf8(tategaki decode_utf8 'お前は、すでに、死んでいる。'), "\n";
    print encode_utf8(tategaki_one_line decode_utf8 'お前は、すでに、死んでいる。');
}

1;

__END__

=encoding utf-8

=head1 NAME

Acme::Tategaki - This Module makes a text vertically.

=head1 SYNOPSIS

    $ perl -MAcme::Tategaki -MEncode -e 'print encode_utf8 tategaki(decode_utf8 "お前は、すでに、死んでいる。"), "\n";'
    死　す　お
    ん　で　前
    で　に　は
    い　︑　︑
    る　　　　
    ︒　　　　

    $ perl -MAcme::Tategaki -MEncode -e 'print encode_utf8 tategaki_one_line(decode_utf8 "お前は、すでに、死んでいる。"), "\n";'
    お
    前
    は
    ︑
    す
    で
    に
    ︑
    死
    ん
    で
    い
    る
    ︒
=head1 DESCRIPTION

Acme::Tategaki makes a text vertically.

=head1 AUTHOR

Kazuhiro Homma E<lt>kazuph@cpan.orgE<gt>

=head1 DEPENDENCIES

L<Array::Transpose>, L<Array::Transpose::Ragged>

=head1 SEE ALSO

L<flippy|https://rubygems.org/gems/flippy>

=head1 LICENSE

Copyright (C) Kazuhiro Homma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

