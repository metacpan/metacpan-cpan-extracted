use strict;
use warnings;

{
    package Acme::Honkidasu;
    use utf8;
    our $VERSION = '0.01';

    use Time::Piece ();

    our $LIST_HONKIDASU = [qw/
        初っ端から飛ばすと後でばてる。来月から本気を出す。
        まだまだ寒い。これではやる気が出ない。来月から本気出す。
        年度の終わりでタイミングが悪い。来月から本気を出す。
        季節の変わり目は体調を崩しやすい。来月から本気を出す。
        区切りの良い４月を逃してしまった。来月から本気を出す。
        梅雨で気分が落ち込む。梅雨明けの来月から本気を出す。
        これからどんどん気温が上昇していく。体力温存の為来月から本気を出す。
        暑すぎて気力がそがれる。来月から本気を出す。
        休みボケが抜けない。無理しても効果が無いので来月から本気を出す。
        中途半端な時期。ここは雌伏の時。来月から本気を出す。
        急に冷えてきた。こういう時こそ無理は禁物。来月から本気を出す。
        もう今年は終わり。今年はチャンスが無かった。来年から本気出す。
    /];
    our $LIST_HONKIDASU_POSITIVE = [qw/
        年の初めだしスタートダッシュで本気出す
        ２月は短いから無駄にしないために本気出す
        年度の変わり目だから最後の追い込みで本気出す
        春は心機一転新しい環境に早く慣れるために本気出す
        落ち込みやすい時期だから油断しないためにも本気出す
        今は梅雨時期だからこそ他の人に差をつけるために本気出す
        カラっといい天気で活力がみなぎるからこそ今まで以上に本気出す
        暑さで気がたるみがちだけど折角盆休みがある今だからこそ本気出す
        気温も落ち着いて活動しやすい時期になってきたしこれから先も本気出す
        寒くなる年末がくる前に面倒なことは片付けておきたいと思うから本気出す
        冷えてきたけど余裕のある年末をこれから迎えるために今の内から本気出す
        今年の締めだからこそ最後まで気を抜かずに今年を１年にするために本気出す
    /];

    our $DETERMINE = sub {
        my $time = shift;
        my $list = shift;
        my $idx = ( $time->mon % scalar(@$list) ) - 1;
        chomp( my $msg = $list->[$idx] );
        return $msg;
    };

    sub import { shift; @_ = ('Time::Piece', @_); goto &Time::Piece::import }
}

{
    package Time::Piece;
    use POSIX::strftime::GNU;

    BEGIN {
        no strict 'refs';
        no warnings "redefine";
        my $orig_time_piece_strftime = \&Time::Piece::strftime;
        *{'Time::Piece::strftime'} = sub {
            my ($self, $format) = @_;
            $format =~ s/%%/%%%%/g if ($format);;
            my $str = POSIX::strftime( $format, CORE::localtime $self->epoch );
            $str =~ s/((%*)%(\(|\)))/(length($2) % 2) ? $1 : $2 . $self->honkidasu( ($3 eq ')') ? 1 : 0 )/ge;
            $str =~ s/%%/%/g;
            return $str;
        };
    }

    sub honkidasu {
        my $self     = shift;
        my $positive = shift;
        my $list
            = ($positive)
            ? $Acme::Honkidasu::LIST_HONKIDASU_POSITIVE
            : $Acme::Honkidasu::LIST_HONKIDASU;
        return (@$list) ? $Acme::Honkidasu::DETERMINE->( $self, $list ) : '';
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Acme::Honkidasu - 本気出すコピペ

=head1 SYNOPSIS

  use 5.010;
  binmode STDOUT, 'utf8';
  use Acme::Honkidasu;
  my $time = localtime;
  say $time->honkidasu;
  say $time->strftime('%F %(');

=head1 DESCRIPTION

Acme::Honkidasu is 本気出す。

=head1 METHOD

=head2 honkidasu

  use Acme::Honkidasu;
  my $time = localtime;
  say $time->honkidasu;
  say $time->honkidasu(1); # positive

本気出す。

=head1 EXTEND strftime

  use Acme::Honkidasu;
  my $time = localtime;
  say $time->strftime('%F %(');
  say $time->strftime('%F %)'); # positive

add conversion specifier character '%(' to 本気出す。

=head1 EXAMPLES

本気出す per hour. (default: per month)

  #!/usr/bin/env perl
  use strict;
  use warnings;
  use 5.010;
  use utf8;
  binmode STDOUT, ":utf8";

  use Acme::Honkidasu;
  $Acme::Honkidasu::DETERMINE = sub {
      my $time = shift;
      my $list = shift;
      my $idx = $time->hour % scalar(@$list);
      chomp( my $msg = $list->[$idx] );
      return $msg;
  };
  $Acme::Honkidasu::LIST_HONKIDASU = [<DATA>];
  say localtime->honkidasu;
  say localtime->strftime('%(');

  __DATA__
  新しい１日。さあはじまる。今日から本気出す。
  まだまだ時間はたっぷりある。焦りは禁物。２時から本気出す。
  YouTube眺めてたら時間のスピードおかしくなる。あぶなかった。3時から本気出す。。
  頭の中にやる気がどんどん湧いてくる。でもまだ早い。はやる気持ちを抑えて、４時から本気出す。
  この時間に起きてる自分が心配だ。体調管理も必要。ひと呼吸おいて、5時から本気出す。
  きっとみんなはまだ寝てる。慌ててはいけない。６時から本気出す。
  眠たいのではない。動き出すのが面倒くさい。あきらめも大切。7時から本気出す。
  夜７時頃の10分間を今くつろぐ時間にもってきてほしい。しかたないから８時から本気出す。
  ぼーっとしてるんじゃない。今日のことを考えてる。頭を整理して９時から本気出す。
  朝から飛ばし過ぎはよくない。大丈夫、ちゃんと計算してる。10時から本気出す。
  みんな朝から元気だ。でも乱されない。自分のペースを守る。11時から本気出す。
  おなか減った。昼に何食べるか考えてたら集中できない。12時から本気出す。
  昼だ。飯食って気分を切り替えて、13時から本気出す。
  飯食っておなかいっぱい。これでは頭がまわらない。14時から本気出す
  おなかいっぱいを通り過ぎて眠たい。15時から本気出す。
  本番は今からだぞ？ここまではウォーミングアップ。16時から本気出す。
  1日の疲れがピークに達してきた。ここで無理しても意味が無い。17時から本気だす。
  本当の勝負は陽が暮れてから。だから慌てない。自分を信じて、18時から本気出す。
  みんな家に帰ってる。なんだろう、この気持ち。心を無にして19時から本気出す。
  今日一日の疲れがあちこちにきてる。ちょっと横になって20時から本気出す。
  ラストスパートに向けて力を溜める。21時から本気出す。
  追い詰められないと本気になれないから、22時から本気出す。
  終わり良ければ全て良し。23時から本気出す。
  一日終わり。今日はチャンスがなかった。明日から本気出す。

=head1 AUTHOR

hayajo E<lt>hayajo@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
