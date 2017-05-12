package Acme::Ikamusume;
use 5.010001;
use strict;
use warnings;
use utf8;
our $VERSION = '0.08';

use File::ShareDir qw/dist_file/;
use Lingua::JA::Kana;

use Text::Mecabist;

sub geso {
    my $self = bless { }, shift;
    my $text = shift // "";

    my $parser = Text::Mecabist->new({
        userdic => dist_file('Acme-Ikamusume', Text::Mecabist->encoding->name .'.dic'),
    });
    
    my $doc = $parser->parse($text, sub {
        my $node = shift;
        return if not $node->readable;
        return if not $node->reading;
        $self->apply_rules($node);
    });
    
    return $doc->join('text');
}

sub godan {
    my ($verb, $from, $to) = @_;
    if (my ($kana) = $verb =~ /(\p{InHiragana})$/) {
        $kana = kana2romaji($kana);
        $kana =~ s/^sh/s/;
        $kana =~ s/^ch/t/;
        $kana =~ s/^ts/t/;
        $kana =~ s/$from$/$to/;
        $kana =~ s/^a$/wa/;
        $kana =~ s/ti/chi/;
        $kana =~ s/tu/tsu/;
        $kana = romaji2hiragana($kana);
    
        $verb =~ s/.$/$kana/;
    }
    $verb;
}

our @rules = (
    
    # userdic extra field
    sub {
        my $node = shift;
        my $word = $node->extra1 or return;
        $node->text($word);
    },

    # IKA: inflection
    sub {
        my $node = shift;
        return if not $node->extra2;
        return if not $node->extra2 =~ /inflection/;
        
        my $prev = $node->prev or return;
        
        if ($prev->is('名詞')) {
            $node->text('じゃなイカ');
        }
        elsif ($prev->is('副詞')) {
            $node->text('でゲソか');
        }
        elsif ($prev->is('助動詞') and
               $prev->surface eq 'です' and
               $prev->prev and $prev->prev->text !~ /^[いイ]{2}$/) {
            $prev->text('じゃなイ');
            $node->text('カ');
        }
        
        if ($prev->text =~ /(?:イー?カ|ゲソ)$/) {
            return;
        }
        elsif ($prev->inflection_type =~ /五段/) {
            $prev->text(godan($prev->text, '.' => 'a'));
            $node->text('なイカ');
        }
        elsif ($prev->inflection_type =~ /一段|カ変|サ変/) {
            $node->text('なイカ');
        }
    },
    
    # formal MASU to casual
    sub {
        my $node = shift;
        if ($node->lemma eq 'ます' and
            $node->is('助動詞') and
            $node->prev && $node->prev->is('動詞')) {

            if ($node->is('基本形')) { # ます
                $node->prev->text($node->prev->lemma);
                $node->text('');

                if ($node->next->pos =~ /^助詞/) {
                    $node->text($node->text . 'でゲソ');
                }
            }
            if ($node->is('連用形') and # ます
                $node->pos3 !~ /五段/) { # 五段 => { -i/っ/ん/い }
                $node->text('');
            }
        }
    },
    
    # no honorific
    sub {
        my $node = shift;
        if ($node->feature =~ /^名詞,接尾,人名,/ and
            $node->prev->text ne 'イカ娘') {
            $node->text('');
        }
    },
  
    # IKA/GESO: replace
    sub {
        my $node = shift;
        my $text = $node->text;

        $text =~ s/い[いー]か(.)/イーカ$1/g;
        $text =~ s/いか/イカ/g;
        $text =~ s/げそ/ゲソ/g;
        $node->text($text);

        return if $text =~ /イー?カ|ゲソ/;

        my $curr = katakana2hiragana($node->reading || "");
       
        $node->text($curr) if $curr =~ s/い[いー]か(.)/イーカ$1/g;
        $node->text($curr) if $curr =~ s/いか/イカ/g;
        $node->text($curr) if $curr =~ s/げそ/ゲソ/g;
        
        my $next = katakana2hiragana(($node->next and $node->next->reading) || "");
        my $prev = katakana2hiragana(join "",
            $node->prev && $node->prev->prev && $node->prev->prev->text,
            $node->prev && $node->prev->text);
        
        $node->text($curr) if $next =~ /^か./ && $curr =~ s/い[いー]$/イー/;
        $node->text($curr) if $prev =~ /い[いー]$/ && $curr =~ s/^か(.)/カ$1/;
        $node->text($curr) if $prev =~ /[いイ]$/ && $curr =~ s/^か/カ/;
        $node->text($curr) if $next =~ /^か/ && $curr =~ s/い$/イ/;
        $node->text($curr) if $next =~ /^そ/ && $curr =~ s/げ$/ゲ/;
        $node->text($curr) if $prev =~ /げ$/ && $curr =~ s/^そ/ソ/;
    },
    
    # IKA/GESO: DA + postp
    sub {
        my $node = shift;
        my $prev = $node->prev or return;

        if ($prev->surface eq 'だ' and
            $prev->text eq 'でゲソ' and
            (
                $node->pos =~ /助詞|助動詞/ or
                $node->is('接尾')
            )
        ) {
            my $kana = kana2romaji($node->text);
            if ($kana =~/^(?:ze|n[aeo]|yo|wa)/) {
                $node->text('');
                $prev->text('じゃなイカ');
            }
            if ($kana =~ /^zo/) {
                $node->text('');
            }
        }
    },
    
    sub {
        my $node = shift;
        my $prev = $node->prev or return;
        my $latest = join "",
            $prev->prev && $prev->prev->text,
            $prev && $prev->text,
            $node->text;

        if ($node->is('終助詞') and
            $latest =~ /(?:でゲソ|じゃなイカ)[よなね]$/) {
            $node->text('');
        }
    },
    
    # IKA: IIKA
    sub {
        my $node = shift;
        my $prev = $node->prev or return;

        if ($prev->text !~ /^(?:[いイ]{2})$/) {
            return;
        }
        if ($node->surface =~ /^(?:です|でしょう)$/ and
            $node->next->surface =~ /^か/) {
            $prev->text('いイ');
            $node->text('');
        }
        if ($node->surface eq 'でしょうか') {
            $prev->text('いイ');
            $node->text('カ');
        }
    },
    
    # GESO/IKA: eos
    sub {
        my $node = shift;
        my $next = $node->next or return;

        if ($next->stat == 3 or # MECAB_EOS_NODE
            (
                $next->is('記号') and
                $next->pos1 =~ /句点|括弧閉|GESO可/
            )
        ) {
            if ($node->pos =~ /^(?:その他|記号|助詞|接頭詞|接続詞|連体詞)/) {
                return;
            }
            
            if ($node->is('助動詞') and
                $node->prev and $node->prev->text eq 'じゃ' and
                $node->surface eq 'ない') {
                $node->text('なイカ');
                return;
            }
            
            if ($node->pos =~ /^助動詞/ and
                $node->prev and $node->prev->text =~ /(?:ゲソ|イー?カ)/) {
                return;
            }
        
            my $latest = join "",
                $node->prev && $node->prev->text,
                $node->text;
            if ($latest =~ /(?:ゲソ|イー?カ)$/) {
                return;
            }
            
            $node->text($node->text . 'でゲソ');
        }
        
        if ($node->is('動詞') and
            $node->inflection_form =~ '基本形' and
            $next->pos =~ /^助詞/) {
            $node->text($node->text . 'でゲソ');
        }
    },
    
    # EBI: accent
    sub {
        my $node = shift;
        my $text = $node->text;
        my @ebi_accent = qw(！ ♪ ♪ ♫ ♬ ♡);
        
        $text =~ s{(エビ|えび|海老)}{
            $1 . $ebi_accent[ int rand scalar @ebi_accent ];
        }e;
        
        $node->text($text);
    },
);

sub apply_rules {
    my ($self, $node) = @_;
    for my $rule (@rules) {
        $rule->($node);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::Ikamusume - The invader comes from the bottom of the sea!

=head1 SYNOPSIS

  use utf8;
  use Acme::Ikamusume;

  print Acme::Ikamusume->geso('イカ娘です。あなたもperlで侵略しませんか？');
  # => イカ娘でゲソ。お主もperlで侵略しなイカ？

=head1 DESCRIPTION

Acme::Ikamusume converts Japanese text into like Ikamusume speak.
Ikamusume, meaning "Squid-Girl", she is a cute Japanese comic/manga
character (L<http://www.ika-musume.com/>).

Try this module here: L<http://ika.koneta.org/>. enjoy!

=head1 METHODS

=over 4

=item $output = Acme::Ikamusume->geso( $input )

=back

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
