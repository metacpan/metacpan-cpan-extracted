package Acme::Samurai;
use 5.010001;
use strict;
use warnings;
use utf8;
our $VERSION = '0.04';

use File::ShareDir qw/dist_file/;
use Lingua::JA::Alphabet::Yomi qw/alphabet2yomi/;
use Lingua::JA::Numbers qw/num2ja/;
use Unicode::Japanese qw/unijp/;

use Text::Mecabist;

sub gozaru {
    my $self = bless { }, shift;
    my $text = shift // "";

    my $parser = Text::Mecabist->new({
        node_format => '%m,%H',
        unk_format  => '%m,%H',
        bos_format  => '%m,%H',
        eos_format  => '%m,%H',
        userdic     => dist_file('Acme-Samurai', Text::Mecabist->encoding->name . '.dic'),
    });

    # natukashi
    $text = unijp($text)->z2hNum->h2zAlpha->getu;

    my $doc = $parser->parse($text, sub {
        my $node = shift;
        $self->apply_rules($node);
    });
    
    return $self->finalize($doc);
}

sub apply_rules {
    my ($self, $node) = @_;
    
    return if not $node->readable;
    
    my $text = $node->text;

    # one to one custom dictionary
    if ($node->extra) {
        $text = $node->extra;
    }
    
    if ($node->is('名詞') or $node->is('記号')) {
        
        # arabic number to kanji
        if ($node->pos1 eq '数' and $node->surface =~ /^[0-9]+$/) {
            # no 位
            if ($node->surface =~ /^0/ or
                $node->prev && $node->prev->surface =~ /[.．]/) {
                
                $text = join "", map { num2ja($_) } split //, $node->surface;
            } else {
                $text = num2ja($node->surface); # with 位
            }
        }
        
        # kanji number to more classic
        elsif ($node->pos1 eq '数') {
            $text =~ tr{〇一二三四五六七八九十百万}
                       {零壱弐参四伍六七八九拾佰萬};
        }
        
        # roman
        elsif ($text =~ /^\p{Latin}+$/) {
            $text = $node->pronunciation if $node->pronunciation;
            $text = alphabet2yomi($text, 'en');
            $text = unijp($text)->kata2hira->getu;
        }
    }    
    
    if ($node->is('動詞')) {
        if ($text =~ /(.+?)(じる)$/) {
            $text = "$1ずる";
        }
        if ($text eq 'い' and
            $node->feature =~ /^動詞,非自立,[*],[*],一段,連用形/ and
            $node->next and
            $node->next->pos !~ /詞/) {
            
            $text = 'おっ' if $node->next->lemma eq 'た';
            $text = 'おり' if $node->next->lemma eq 'ます';
        }
    }

    if ($node->is('形容詞')) {
        if ($text =~ /^(.+?)(しい|しく)$/) {
            $text = $1 . { 'しい' => 'しき', 'しく' => 'しゅう' }->{$2};
        }
    }
    
    if ($node->is('助詞')) {
        if ($node->feature eq '助詞,終助詞,*,*,*,*,の,の,の,のか' and
            $node->prev and
            $node->prev->surface eq 'な') {
            $node->prev->skip(1);
            $text = 'なの';
        }
        elsif ($text eq 'ので' and
            $node->prev and
            $node->prev->surface eq 'な') {
            $node->prev->skip(1);
            $text = 'ゆえに';
        }
        elsif ($node->surface eq 'ね' and
            $node->prev and
            $node->prev->surface eq 'の') {
            $text = 'だな';
        }
    }
    
    if ($node->is('助動詞')) {
        if ($text eq 'ない') {
            if ($node->prev and
                $node->prev->surface eq 'し' and
                $node->next and
                $node->next->surface and
                $node->next->pos !~ /詞/) {
                $node->prev->skip(1);
                $text = 'せぬ';
            }
            if ($node->prev and
                $node->prev->surface ne 'し' and
                $node->prev->inflection_form eq '未然形') {
                $text = 'ぬ';
            }
        }
        elsif ($text eq 'なけれ') {
            if ($node->prev and
                $node->prev->surface eq 'し') {
                $node->prev->skip(1);
                $text = 'せね';
            }
        }
    }
    
    if ($node->is('感動詞')) {
        if ($node->next and
            $node->next->pos !~ /詞/) {
            $text = $node->extra if $node->extra;
            $text .= 'でござる';
        }
    }

    $node->text($text);
}

sub finalize {
    my ($self, $doc) = @_;
    my $text = $doc->join('text');
    $text =~ s/(?:ておりまする|ていまする?)\b/ており候/g;
    $text =~ s/(?:どうも)?かたじけない(?:ございま(?:する|す|した))?/かたじけない/g;
    $text;
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::Samurai - Speak like a Samurai

=head1 SYNOPSIS

  use utf8;
  use Acme::Samurai;

  Acme::Samurai->gozaru("私、侍です"); # => "それがし、侍でござる"

=head1 DESCRIPTION

Translates Japanese to 時代劇
(L<http://en.wikipedia.org/wiki/Jidaigeki>) speak.

Test form: L<http://samurai.koneta.org/>

=head1 METHODS

=over 4

=item gozaru( $text )

=back

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 SPECIAL THANKS

kazina, this module started from てきすたー dictionary.
L<http://kazina.com/texter/index.html>

and Hiroko Nagashima, Shin Yamauchi for addition samurai vocabulary.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=for stopwords hiroko nagashima shin yamauchi de gozaru kazina

=cut
