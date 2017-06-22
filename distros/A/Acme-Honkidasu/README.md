# NAME

Acme::Honkidasu - 本気出すコピペ

# SYNOPSIS

    use 5.010;
    binmode STDOUT, 'utf8';
    use Acme::Honkidasu;
    my $time = localtime;
    say $time->honkidasu;
    say $time->strftime('%F %(');

# DESCRIPTION

Acme::Honkidasu is 本気出す。

# METHODS

## honkidasu

    use Acme::Honkidasu;
    my $time = localtime;
    say $time->honkidasu;
    say $time->honkidasu(1); # positive

本気出す。

# EXTEND strftime

    use Acme::Honkidasu;
    my $time = localtime;
    say $time->strftime('%F %(');
    say $time->strftime('%F %)'); # positive

add conversion specifier character '%(' to 本気出す。

# EXAMPLES

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

# AUTHOR

hayajo <hayajo@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
