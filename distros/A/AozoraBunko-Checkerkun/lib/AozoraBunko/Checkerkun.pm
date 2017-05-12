package AozoraBunko::Checkerkun;
our $VERSION = "0.12";

use 5.008001;
use strict;
use warnings;
use utf8;

use Carp           qw//;
use File::ShareDir qw//;
use YAML::Tiny     qw//;
use Encode         qw//;
use Lingua::JA::Halfwidth::Katakana;

my $YAML_FILE = File::ShareDir::dist_file('AozoraBunko-Checkerkun', 'hiden_no_tare.yml');
my $YAML = YAML::Tiny->read($YAML_FILE)->[0];
my $ENC = Encode::find_encoding("Shift_JIS");

my %VALID_OUTPUT_FORMAT;
@VALID_OUTPUT_FORMAT{qw/plaintext html/} = ();

# [78hosetsu_tekiyo] 78互換包摂の対象となる不要な外字注記をチェックする
our $KUTENMEN_78HOSETSU_TEKIYO = $YAML->{'kutenmen_78hosetsu_tekiyo'};

# [hosetsu_tekiyo] 包摂の対象となる不要な外字注記をチェックする
our $KUTENMEN_HOSETSU_TEKIYO = $YAML->{'kutenmen_hosetsu_tekiyo'};

# 新JIS漢字で包摂基準の適用除外となる104字
our $JYOGAI = $YAML->{'jyogai'};

# 78互換文字
our $J78 = $YAML->{'j78'};

# 間違えやすい文字
# かとうかおりさんの「誤認識されやすい文字リスト」から
# http://plaza.users.to/katokao/digipr/digipr_charlist.html
our $GONIN1 = $YAML->{'gonin1'};

# 誤認2
our $GONIN2 = $YAML->{'gonin2'};

# 誤認3
# （砂場清隆さんの入力による）
our $GONIN3 = $YAML->{'gonin3'};

# 新字体・旧字体対応リスト
our $KYUJI = $YAML->{'kyuji'};

# 異体字
our $ITAIJI = $YAML->{'itaiji'};

sub _default_options
{
    return {
        'gaiji'            => 1, # JIS外字をチェックする
        'hansp'            => 1, # 半角スペースをチェックする
        'hanpar'           => 1, # 半角カッコをチェックする
        'zensp'            => 0, # 全角スペースをチェックする
        'zentilde'         => 1, # 全角チルダをチェックする
        '78hosetsu_tekiyo' => 1, # 78互換包摂の対象となる不要な外字注記をチェックする
        'hosetsu_tekiyo'   => 1, # 包摂の対象となる不要な外字注記をチェックする
        '78'               => 0, # 78互換包摂29字をチェックする
        'jyogai'           => 0, # 新JIS漢字で包摂規準の適用除外となる104字をチェックする
        'gonin1'           => 0, # 誤認しやすい文字をチェックする(1)
        'gonin2'           => 0, # 誤認しやすい文字をチェックする(2)
        'gonin3'           => 0, # 誤認しやすい文字をチェックする(3)
        'simplesp'         => 0, # 半角スペースは「_」で、全角スペースは「□」で出力する
        'kouetsukun'       => 0, # 旧字体置換可能チェッカー「校閲君」を有効にする
        'output_format'    => 'plaintext', # plaintext または html
    };
}

sub new
{
    my $class = shift;
    my %args  = (ref $_[0] eq 'HASH' ? %{$_[0]} : @_);

    my $options = $class->_default_options;

    for my $key (keys %args)
    {
        if ( ! exists $options->{$key} ) { Carp::croak "Unknown option: '$key'"; }
        else
        {
            if ($key eq 'output_format')
            {
                Carp::croak "Output format option must be 'plaintext' or 'html'" unless exists $VALID_OUTPUT_FORMAT{ $args{$key} };
            }

            $options->{$key} = $args{$key};
        }
    }

    bless $options, $class;
}

sub _tag_html
{
    my ($plaintext, $tag_name, $msg) = @_;

    return qq|<span data-checkerkun-tag="$tag_name">$plaintext</span>| unless defined $msg;
    return qq|<span data-checkerkun-tag="$tag_name" data-checkerkun-message="$msg">$plaintext</span>|;
}

# 例：
#
# ※［＃「口＋亞」、第3水準1-15-8、144-上-9］
# が
# ※［＃「口＋亞」、第3水準1-15-8、144-上-9］→[78hosetsu_tekiyo]【唖】
# に変換され、
#
# ※［＃「にんべん＋曾」、第3水準1-14-41、144-上-9］
# が
# ※［＃「にんべん＋曾」、第3水準1-14-41、144-上-9］→[hosetsu_tekiyo]【僧】
# に変換される。
#
sub _check_all_hosetsu_tekiyo
{
    my ($self, $chars_ref, $index) = @_;

    my ($replace, $usedlen);

    my $rear_index = $index + 80;
    $rear_index = $#{$chars_ref} if $rear_index > $#{$chars_ref};

    if ( join("", @{$chars_ref}[$index .. $rear_index]) =~ /^(※［＃.*?水準(\d+\-\d+\-\d+).*?］)/ )
    {
        my ($match, $kutenmen) = ($1, $2);

        if ( $self->{'78hosetsu_tekiyo'} && exists $KUTENMEN_78HOSETSU_TEKIYO->{$kutenmen} )
        {
            if ($self->{'output_format'} eq 'plaintext')
            {
                $replace = "$match→[78hosetsu_tekiyo]【$KUTENMEN_78HOSETSU_TEKIYO->{$kutenmen}】";
            }
            elsif ($self->{'output_format'} eq 'html')
            {
                $replace = _tag_html($match, '78hosetsuTekiyo', $KUTENMEN_78HOSETSU_TEKIYO->{$kutenmen});
            }

            $usedlen = length $match;
        }
        elsif ( $self->{'hosetsu_tekiyo'} && exists $KUTENMEN_HOSETSU_TEKIYO->{$kutenmen} )
        {
            if ($self->{'output_format'} eq 'plaintext')
            {
                $replace = "$match→[hosetsu_tekiyo]【$KUTENMEN_HOSETSU_TEKIYO->{$kutenmen}】";
            }
            elsif ($self->{'output_format'} eq 'html')
            {
                $replace = _tag_html($match, 'hosetsuTekiyo', $KUTENMEN_HOSETSU_TEKIYO->{$kutenmen});
            }

            $usedlen = length $match;
        }
    }

    return ($replace, $usedlen);
}

sub _is_gaiji
{
    my $char = shift; # コピーしないと元の文字が消失するので

    # UTF-8からSJISに変換できなければ JIX X 0208:1997 外字と判定
    return length $ENC->encode($char, Encode::FB_QUIET) ? 0 : 1;
}

sub check
{
    my ($self, $text) = @_;

    return undef unless defined $text;

    my $output_format = $self->{'output_format'};

    my @chars = split(//, $text);

    my $checked_text = '';

    for (my $i = 0; $i < @chars; $i++)
    {
        my $char = $chars[$i];

        if ( $self->{simplesp} && ($char eq "\x{0020}" || $char eq "\x{3000}") )
        {
            if ($output_format eq 'plaintext')
            {
                   if ($char eq "\x{0020}") { $checked_text .= '_';  }
                elsif ($char eq "\x{3000}") { $checked_text .= '□'; }
            }
            elsif ($output_format eq 'html')
            {
                   if ($char eq "\x{0020}") { $checked_text .= _tag_html('_', 'simplesp');  }
                elsif ($char eq "\x{3000}") { $checked_text .= _tag_html('□', 'simplesp'); }
            }

            next;
        }

        if ($char =~ /[\x{0000}-\x{0009}\x{000B}\x{000C}\x{000E}-\x{001F}\x{007F}-\x{009F}]/)
        {
            # 改行は含まない

            if ($output_format eq 'plaintext')
            {
                $checked_text .= $char . '[ctrl]（' . sprintf("U+%04X", ord $char) . '）';
            }
            elsif ($output_format eq 'html')
            {
                $checked_text .= _tag_html($char, 'ctrl', sprintf("U+%04X", ord $char));
            }
        }
        elsif ($char =~ /\p{InHalfwidthKatakana}/)
        {
            if ($output_format eq 'plaintext')
            {
                $checked_text .= $char . '[hankata]';
            }
            elsif ($output_format eq 'html')
            {
                $checked_text .= _tag_html($char, 'hankata', '半角カタカナ');
            }
        }
        elsif ($self->{'hansp'} && $char eq "\x{0020}")
        {
            if ($output_format eq 'plaintext')
            {
                $checked_text .= $char . '[hansp]';
            }
            elsif ($output_format eq 'html')
            {
                $checked_text .= _tag_html($char, 'hansp', '半角スペース');
            }
        }
        elsif ($self->{'zensp'} && $char eq "\x{3000}")
        {
            if ($output_format eq 'plaintext')
            {
                $checked_text .= $char . '[zensp]';
            }
            elsif ($output_format eq 'html')
            {
                $checked_text .= _tag_html($char, 'zensp', '全角スペース');
            }
        }
        elsif ($self->{'zentilde'} && $char eq "\x{FF5E}")
        {
            if ($output_format eq 'plaintext')
            {
                $checked_text .= $char . '[zentilde]';
            }
            elsif ($output_format eq 'html')
            {
                $checked_text .= _tag_html($char, 'zentilde', '全角チルダ');
            }
        }
        elsif ( $self->{hanpar} && ($char eq '(' || $char eq ')') )
        {
            if ($output_format eq 'plaintext')
            {
                $checked_text .= $char . '[hanpar]';
            }
            elsif ($output_format eq 'html')
            {
                $checked_text .= _tag_html($char, 'hanpar', '半角括弧');
            }
        }
        elsif ( $char eq '※' && ($self->{'78hosetsu_tekiyo'} || $self->{'hosetsu_tekiyo'}) )
        {
            my ($replace, $usedlen) = $self->_check_all_hosetsu_tekiyo(\@chars, $i);

            if ($replace)
            {
                $checked_text .= $replace;
                $i += ($usedlen - 1);
                next;
            }
        }
        else
        {
            # 秘伝のタレによるチェック
            # 　複数のタグに該当する文字でも↓のif文で真っ先にマッチした１つのタグしかつかないことに注意。
            # 　複数タグに対応してもいいが、複数タグに該当する文字は9字で、その9字のためにコードと出力結果を複雑化させるのも微妙なところ。
            #
            if ($self->{'78'} && $J78->{$char})
            {
                if ($output_format eq 'plaintext')
                {
                    $checked_text .= $char . '[78]（' . $J78->{$char} . '）';
                }
                elsif ($output_format eq 'html')
                {
                    $checked_text .= _tag_html($char, '78', $J78->{$char});
                }
            }
            elsif ($self->{'jyogai'} && $JYOGAI->{$char})
            {
                if ($output_format eq 'plaintext')
                {
                    $checked_text .= $char . '[jyogai]';
                }
                elsif ($output_format eq 'html')
                {
                    $checked_text .= _tag_html($char, 'jyogai', '新JIS漢字で包摂規準の適用除外となる');
                }
            }
            elsif ($self->{'kouetsukun'} && $KYUJI->{$char})
            {
                if ($output_format eq 'plaintext')
                {
                    $checked_text .= "▼$char$KYUJI->{$char}▲";
                }
                elsif ($output_format eq 'html')
                {
                    $checked_text .= _tag_html($char, 'kyuji', $KYUJI->{$char});
                }
            }
            elsif ($self->{'kouetsukun'} && $ITAIJI->{$char})
            {
                if ($output_format eq 'plaintext')
                {
                    $checked_text .= "▼$char$ITAIJI->{$char}▲";
                }
                elsif ($output_format eq 'html')
                {
                    $checked_text .= _tag_html($char, 'itaiji', $ITAIJI->{$char});
                }
            }
            elsif ($self->{'gonin1'} && $GONIN1->{$char})
            {
                if ($output_format eq 'plaintext')
                {
                    $checked_text .= $char . '[gonin1]（' . $GONIN1->{$char} . '）';
                }
                elsif ($output_format eq 'html')
                {
                    $checked_text .= _tag_html($char, 'gonin1', $GONIN1->{$char});
                }
            }
            elsif ($self->{'gonin2'} && $GONIN2->{$char})
            {
                if ($output_format eq 'plaintext')
                {
                    $checked_text .= $char . '[gonin2]（' . $GONIN2->{$char} . '）';
                }
                elsif ($output_format eq 'html')
                {
                    $checked_text .= _tag_html($char, 'gonin2', $GONIN2->{$char});
                }
            }
            elsif ($self->{'gonin3'} && $GONIN3->{$char})
            {
                if ($output_format eq 'plaintext')
                {
                    $checked_text .= $char . '[gonin3]（' . $GONIN3->{$char} . '）';
                }
                elsif ($output_format eq 'html')
                {
                    $checked_text .= _tag_html($char, 'gonin3', $GONIN3->{$char});
                }
            }
            elsif ( $self->{'gaiji'} && _is_gaiji($char) )
            {
                # 秘伝のタレに外字が含まれていないことがテストで保証されているのでこの位置で問題ない
                # コントロール文字に外字があるが、コントロール文字なら必ず 'ctrl' とタグ付けされるのでそれで良しとする。
                if ($output_format eq 'plaintext')
                {
                    $checked_text .= $char . '[gaiji]';
                }
                elsif ($output_format eq 'html')
                {
                    $checked_text .= _tag_html($char, 'gaiji', 'JIS外字');
                }
            }
            else { $checked_text .= $char; }
        }
    }

    return $checked_text;
}

1;

__END__

=encoding utf-8

=head1 NAME

AozoraBunko::Checkerkun - 青空文庫の工作員のための文字チェッカー（作：結城浩）をライブラリ化したもの

=head1 SYNOPSIS

  use AozoraBunko::Checkerkun;
  use utf8;

  my $checker1 = AozoraBunko::Checkerkun->new;
  $checker1->check('森※［＃「區＋鳥」、第3水準1-94-69］外💓'); # => '森※［＃「區＋鳥」、第3水準1-94-69］→[78hosetsu_tekiyo]【鴎】外💓[gaiji]'
  $checker1->check('森鷗外'); # => '森鷗[gaiji]外'
  $checker1->check('森鴎外'); # => '森鴎外'

  my $checker2 = AozoraBunko::Checkerkun->new({ output_format => 'html', gonin1 => 1, gonin2 => 1, gonin3 => 1 });
  $checker2->check('桂さんが柱を壊した。'); # => '<span data-checkerkun-tag="gonin3" data-checkerkun-message="かつら">桂</span>さんが<span data-checkerkun-tag="gonin3" data-checkerkun-message="はしら">柱</span>を壊した。'

  my $checker3 = AozoraBunko::Checkerkun->new({ kouetsukun => 1 });
  $checker3->check('薮さん'); # => '▼薮藪籔▲さん'

=head1 DESCRIPTION

AozoraBunko::Checkerkun は、青空文庫工作員のための文字チェッカーで、結城浩氏が作成したスクリプトを私がライブラリ化したものです。

大野裕・結城浩・ゼファー生の各氏による旧字体置換可能チェッカー「校閲君」もこのライブラリに組み込まれています。

=head1 METHODS

=head2 $checker = AozoraBunko::Checkerkun->new(\%option)

新しい AozoraBunko::Checkerkun インスタンスを生成します。

  my $checker = AozoraBunko::Checkerkun->new(
      'gaiji'            => 1, # JIS外字をチェックする
      'hansp'            => 1, # 半角スペースをチェックする
      'hanpar'           => 1, # 半角カッコをチェックする
      'zensp'            => 0, # 全角スペースをチェックする
      'zentilde'         => 1, # 全角チルダをチェックする
      '78hosetsu_tekiyo' => 1, # 78互換包摂の対象となる不要な外字注記をチェックする
      'hosetsu_tekiyo'   => 1, # 包摂の対象となる不要な外字注記をチェックする
      '78'               => 0, # 78互換包摂29字をチェックする
      'jyogai'           => 0, # 新JIS漢字で包摂規準の適用除外となる104字をチェックする
      'gonin1'           => 0, # 誤認しやすい文字をチェックする(1)
      'gonin2'           => 0, # 誤認しやすい文字をチェックする(2)
      'gonin3'           => 0, # 誤認しやすい文字をチェックする(3)
      'simplesp'         => 0, # 半角スペースは「_」で、全角スペースは「□」で出力する
      'kouetsukun'       => 0, # 旧字体置換可能チェッカー「校閲君」を有効にする（html出力時は kyuji か itaiji のチェッカー君タグ情報が付きます。）
      'output_format'    => 'plaintext', # 出力フォーマット（plaintext または html）
  );

上記のコードで設定されている値がデフォルト値です。

=head2 $checked_text = $checker->check($text)

new で指定したオプションでテキストをチェックします。戻り値はチェック後のテキストです。

=head1 秘伝のタレ（文字チェック用ハッシュリファレンス）へのアクセス

このモジュールを use すると以下の文字チェック用ハッシュリファレンスへアクセス可能になります。

  # 78互換包摂の対象となる不要な外字注記をチェックする
  $AozoraBunko::Checkerkun::KUTENMEN_78HOSETSU_TEKIYO;

  # 包摂の対象となる不要な外字注記をチェックする
  $AozoraBunko::Checkerkun::KUTENMEN_HOSETSU_TEKIYO;

  # 新JIS漢字で包摂基準の適用除外となる104字
  $AozoraBunko::Checkerkun::JYOGAI;

  # 78互換文字
  $AozoraBunko::Checkerkun::J78;

  # 誤認1
  # 間違えやすい文字
  # かとうかおりさんの「誤認識されやすい文字リスト」から
  # http://plaza.users.to/katokao/digipr/digipr_charlist.html
  $AozoraBunko::Checkerkun::GONIN1;

  # 誤認2
  $AozoraBunko::Checkerkun::GONIN2;

  # 誤認3
  # （砂場清隆さんの入力による）
  $AozoraBunko::Checkerkun::GONIN3;

  # 新字体・旧字体対応リスト
  $AozoraBunko::Checkerkun::KYUJI;

  # 異体字
  $AozoraBunko::Checkerkun::ITAIJI;

=head1 秘伝のタレを増量させたい

電子メールや github で要望を受け付けております。

=head1 SEE ALSO

L<Net::AozoraBunko>

L<本ライブラリを用いた新しいチェッカー君|http://chobitool.com/checkerkun/>

L<青空文庫作業マニュアル【入力編】|http://www.aozora.gr.jp/aozora-manual/index-input.html>

L<チェッカー君|http://www.aozora.jp/tools/checker.cgi>

L<外字|http://www.aozora.gr.jp/annotation/external_character.html>

L<波ダッシュ - Wikipedia|https://ja.wikipedia.org/wiki/%E6%B3%A2%E3%83%80%E3%83%83%E3%82%B7%E3%83%A5#Unicode.E3.81.AB.E9.96.A2.E9.80.A3.E3.81.99.E3.82.8B.E5.95.8F.E9.A1.8C>

L<包摂 (文字コード) - Wikipedia|https://ja.wikipedia.org/wiki/%E5%8C%85%E6%91%82_(%E6%96%87%E5%AD%97%E3%82%B3%E3%83%BC%E3%83%89)>

L<JIS漢字で包摂の扱いが変わる文字（[78] [jyogai] など）|http://www.aozora.gr.jp/newJIS-Kanji/gokan_henkou_list.html>

L<校閲君を使ってみよう|http://www.aozora.gr.jp/tools/kouetsukun/online_kouetsukun.html>

L<Embedding custom non-visible data with the data-* attributes|http://www.w3.org/TR/html5/dom.html#embedding-custom-non-visible-data-with-the-data-*-attributes>

=head1 LICENSE

Copyright (C) pawa.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

pawa E<lt>pawa@pawafuru.comE<gt>

=cut
