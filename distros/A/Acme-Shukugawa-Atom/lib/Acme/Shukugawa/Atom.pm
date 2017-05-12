# $Id: /mirror/coderepos/lang/perl/Acme-Shukugawa-Atom/trunk/lib/Acme/Shukugawa/Atom.pm 47728 2008-03-14T01:07:28.622095Z daisuke  $

package Acme::Shukugawa::Atom;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use utf8;
use Encode qw(decode_utf8);
use File::ShareDir;
use Text::MeCab;
use YAML ();

our $VERSION = '0.00004';

__PACKAGE__->mk_accessors($_) for qw(custom_words);

# Special case handling -- this could be optimized further
# put it in a sharefile later
our ($CONFIG, @DEFAULT_WORDS, $RE_EXCEPTION, $RE_SMALL, $RE_SYLLABLE, $RE_NBAR);
BEGIN
{
    my $config = YAML::LoadFile( 
        $CONFIG || File::ShareDir::module_file(__PACKAGE__, 'config.yaml') );
    $RE_SMALL    = decode_utf8("[ャュョッー]");
    $RE_SYLLABLE = decode_utf8("(?:.$RE_SMALL?)");
    $RE_NBAR     = decode_utf8("^ンー");
    @DEFAULT_WORDS = map { 
        (decode_utf8($_->[0]), decode_utf8($_->[1]))
    } @{ $config->{custom_words} || [] };
}

sub _create_exception_re
{
    my $self = shift;
    my $custom = $self->custom_words;

    return decode_utf8(join("|",
        map { $custom->[$_ * 2 + 1] } (0..(scalar(@$custom) - 1)/2) ));
}

sub translate
{
    my $self   = shift;
    my $string = decode_utf8(shift);

    if (! ref $self) {
        $self = $self->new({ custom_words => \@DEFAULT_WORDS, @_ });
    }

    # Create local RE_EXCEPTION
    local $RE_EXCEPTION = $self->_create_exception_re;

    $self->preprocess(\$string);
    $self->runthrough(\$string);
    $self->postprocess(\$string);

    return $string;
}

sub preprocess
{
    my ($self, $strref) = @_;
    my $custom = $self->custom_words;

    for(0..(scalar(@$custom) - 1)/2) {
        my $pattern = $custom->[$_ * 2];
        my $replace = $custom->[$_ * 2 + 1];
        $$strref =~ s/$pattern/$replace/g;
    }
}

sub runthrough
{
    my ($self, $strref) = @_;

    my $mecab = Text::MeCab->new;

    # First, make it all katakana, except for where the surface is already
    # in hiragana
    my $ret = '';

    foreach my $text (split(/($RE_EXCEPTION|\s+)/, $$strref)) {
        if ($text =~ /$RE_EXCEPTION/) {
            $ret .= $text;
            next;
        }

        if ($text !~ /\S/) {
            $ret .= $text;
            next;
        }

        foreach (my $node = $mecab->parse($text); $node; $node = $node->next) {
            next unless $node->surface;

            my $surface = decode_utf8($node->surface);
            my $feature = decode_utf8($node->feature);
            my ($type, $yomi) = (split(/,/, $feature))[0,8];
# warn "$surface -> $type, $yomi";

            if ($surface eq '上手') {
                $ret .= 'マイウー';
                next;
            }

            if ($type eq '動詞' && $node->next) {
                # 助動詞を計算に入れる
                my $next_feature = decode_utf8($node->next->feature);
                my ($next_type, $next_yomi) = (split(/,/, $next_feature))[0,8];
                if ($next_type eq '助動詞') {
                    $yomi .= $next_yomi;
                    $node = $node->next;
                }
            }

            if ($type =~ /副詞|助動詞|形容詞|接続詞|助詞/ && $surface =~ /^\p{InHiragana}+$/) {
                $ret .= $surface;
            } elsif ($yomi) {
                $ret .= $self->atomize($yomi) || $surface;
            } else {
                $ret .= $surface;
            }
        }
    }
    $$strref = $ret;
}

sub postprocess {}

# シースールール
# 寿司→シースー
# ン、が最後だったらひっくり返さない
sub apply_shisu_rule
{
    my ($self, $yomi) = @_;
    return $yomi if $yomi =~ s{^($RE_SYLLABLE)($RE_SYLLABLE)$}{
        my ($a, $b) = ($1, $2);
        $a =~ s/ー$//;
        $b =~ s/ー$//;
        "${b}ー${a}ー";
    }e;
    return;
}

# ワイハールール
# ハワイ→ワイハー
sub apply_waiha_rule
{
    my ($self, $yomi) = @_;

# warn "WAIHA $yomi";
    if ($yomi =~ s/^(${RE_SYLLABLE}[$RE_NBAR]?)([^$RE_NBAR].)$/$2$1/) {
        $yomi =~ s/(^.[^ー].*[^ー])$/$1ー/;
        return $yomi;
    }
    return;
}

# クリビツルール
# びっくり→クリビツ
sub apply_kuribitsu_rule
{
    my ($self, $yomi) = @_;

# warn "KURIBITSU $yomi";
    if ($yomi =~ s/^(${RE_SYLLABLE}.)([^$RE_NBAR]${RE_SYLLABLE}$)/$2$1/) {
        return $yomi;
    }
    return;
}

sub atomize
{
    my ($self, $yomi) = @_;
    $yomi =~ s/ー+/ー/g;

    # Length
    my $word_length = length($yomi);
    my $length = $word_length - ($yomi =~ /$RE_SMALL/g);
    if ($length == 3 && $yomi =~ s/^(${RE_SYLLABLE})ッ/${1}ツ/) {
# warn "Special rule!";
        $length = 4;
    }
    my $done = 0;

# warn "$yomi LENGTH: $length";
    if ($length == 2) {
        my $tmp = $self->apply_shisu_rule($yomi);
        if ($tmp) {
            $yomi = $tmp;
            $done = 1;
        }
    }

    if ($length == 3) {
        my $tmp = $self->apply_waiha_rule($yomi);
        if ($tmp) {
            $yomi = $tmp;
            $done = 1;
        }
    }

    if ($length == 4) { # 4 character words tend to have special xformation
        my $tmp = $self->apply_kuribitsu_rule($yomi);
        if ($tmp) {
            $yomi = $tmp;
            $done = 1;
        }
    }

    if (! $done) {
        $yomi =~ s/(.(?:ー+)?)$//;
        $yomi = $1 . $yomi;
    }

    $yomi =~ s/ッ$/ツ/;
    return $yomi;
}


1;

__END__

=encoding UTF-8

=head1 NAME

Acme::Shukugawa::Atom - ギロッポンにテッペンでバミった

=head1 SYNOPSIS

  use Acme::Shukugawa::Atom;
  my $newstring = Acme::Shukugawa::Atom->translate($string);

  # By default, share/config.yaml is used (via File::ShareDir) for custom
  # fixed replacements. You can however override this by specifying the
  # alternate config filename at load time
  BEGIN
  {
    $Acme::Shukugawa::Atom::CONFIG = '/path/to/config.yaml';
  }
  use Acme::Shukugawa::Atom;
  
  # Or you can specify them (on top of the default words) at run time
  my $atom = Acme::Shukugawa::Atom->new(
    # The default values are stored in @Acme::Shukugawa::Atom::DEFAULT_WORDS
    custom_words => [
      'regexp1' => 'replacement1'
      'regexp2' => 'replacement2'
      'regexp3' => 'replacement3'
      'regexp4' => 'replacement4'
      ....
    ]
  );
  my $newstring = $atom->translate($string);

  # shorter way
  my $newstring = Acme::Shukugawa::Atom->translate($string,
    custom_words => [ ... ]
  );

=head1 DESCRIPTION

夙川アトム風な文章を作成します。

まだまだ足りない部分がありますので、もしよければt/01_basic.tに希望する変換前と
変換後の結果を書いてテストをアップデートしてお知らせください。変換を
可能にするようにコードを修正してみます。

svnが使える方はこちらからどうぞ：

  http://svn.coderepos.org/share/lang/perl/Acme-Shukugawa-Atom/trunk

板付き語（固定変換）を足す場合はインスタンス毎にcustom_wordsを変更するか、
share/config.yaml のcustom_wordsに追加してください。

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
