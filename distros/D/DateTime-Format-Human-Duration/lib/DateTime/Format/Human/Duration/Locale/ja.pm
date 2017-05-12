package DateTime::Format::Human::Duration::Locale::ja;

use strict;
use warnings;

sub get_human_span_from_units {
    my ($duration_units, $args_hr) = @_;

    my %n = map { ($_ => abs $duration_units->{$_}) } keys %$duration_units;

    #
    # もっとよい訳にしてください！ m(_ _)m
    #
    #   考えてみると日本語って難しい。。。
    #   とりあえず「前」「後」を付けた場合と、無しの場合で変じゃないように。
    #   こんなんで悩むとは思わなかったが、日本語使えてない!?
    #
    #   * 公文書は「一箇月」新聞は「一カ月」だそうです。
    #
    #   採用
    #       1年2ヶ月前
    #       1年2ヶ月
    #       1年2ヶ月3分前
    #       1年2ヶ月3分
    #       1時間2秒
    #       1時間前
    #       1週間前 # ググルと 1週間前 より 1週前 のほうが多いが、レースなどか。。。
    #       1週間
    #
    #   不採用
    #       1ヶ年2ヶ月3分前
    #       1年2ヶ月3分間前
    #       1年2ヶ月3分間
    #       1時間2秒間
    #       1週前
    #       1週後
    #
    my $s = join "",
        ( $n{years}   ? "$n{years}年"    : () ),
        ( $n{months}  ? "$n{months}ヶ月" : () ),
        ( $n{weeks}   ? "$n{weeks}週間"  : () ),
        ( $n{days}    ? "$n{days}日"     : () ),
        ( $n{hours}   ? "$n{hours}時間"  : () ),
        ( $n{minutes} ? "$n{minutes}分"  : () ),
        ( $n{seconds} ? "$n{seconds}秒"  : () );

    my $past = grep { $_ < 0 } values %$duration_units;
    my $say = '';
    if ($past && $args_hr->{past}) {
        $say = $args_hr->{past};
    } elsif (! $past && $args_hr->{future}) {
        $say = $args_hr->{future};
    }
    if ($say) {
        $s = $say =~ m{%s} ? sprintf($say, $s): "$s$say";
    }

    unless ($s) {
        $s = $args_hr->{no_time} || "時間なし";
    }

    return $s;
}

1;
