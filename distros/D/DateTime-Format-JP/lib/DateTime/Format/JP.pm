##----------------------------------------------------------------------------
## Japanese DateTime Parser/Formatter - ~/lib/DateTime/Format/JP.pm
## Version v0.1.4
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/07/18
## Modified 2023/10/11
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DateTime::Format::JP;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Exporter );
    use vars qw(
        $VERSION $DATETIME_PATTERN_1_RE $DATETIME_PATTERN_2_RE $DATETIME_PATTERN_3_RE $DICT
        $ZENKAKU_NUMBERS $KANJI_NUMBERS $ZENKAKU_TO_ROMAN $KANJI_TO_ROMAN $WEEKDAYS
        $WEEKDAYS_RE $TIME_RE $TIME_ZENKAKU_RE $TIME_KANJI_RE $ERROR
    );
    use Nice::Try;
    our $VERSION = 'v0.1.4';
    our $DICT = [];
    our $ZENKAKU_NUMBERS = [];
    our $KANJI_NUMBERS   = [];
    our $ZENKAKU_TO_ROMAN= {};
    our $KANJI_TO_ROMAN  = {};
    our $WEEKDAYS        = [];
    our $WEEKDAYS_RE;
    our $TIME_RE;
    our( $DATETIME_PATTERN_1_RE, $DATETIME_PATTERN_2_RE, $DATETIME_PATTERN_3_RE )
};

use strict;
use warnings;

{
    use utf8;
    $ZENKAKU_NUMBERS = [qw(０ １ ２ ３ ４ ５ ６ ７ ８ ９)];
    $KANJI_NUMBERS   = [qw(〇 一 二 三 四 五 六 七 八 九 十 十一 十二 十三 十四 十五 十六 十七 十八 十九)];
    $WEEKDAYS        = [qw( 月 火 水 木 金 土 日 )];
    for( 0..9 )
    {
        $ZENKAKU_TO_ROMAN->{ $ZENKAKU_NUMBERS->[$_] } = $_;
        $KANJI_TO_ROMAN->{ $KANJI_NUMBERS->[$_] } = $_;
    }
    $WEEKDAYS_RE = qr/(?:月|火|水|木|金|土|日)/;
    $TIME_RE = qr/
        (?<ampm>午前|午後)?
        (?<hour>\d{1,2})時
        (?:
            (?<minute>\d{1,2})分?
            (?:
                (?<=分)
                (?<second>\d{1,2})秒
            )?
        )?
    /x;
    $TIME_ZENKAKU_RE = qr/
        (?<ampm>午前|午後)?
        (?<hour>[０１２３４５６７８９]{1,2})時
        (?:
            (?<minute>[０１２３４５６７８９]{1,2})分?
            (?:
                (?<=分)
                (?<second>[０１２３４５６７８９]{1,2})秒
            )?
        )?
    /x;
    $TIME_KANJI_RE = qr/
        (?<ampm>午前|午後)?
        (?<hour>[〇一二三四五六七八九十]{1,3})時
        (?:
            (?<minute>[〇一二三四五六七八九十]{1,3})分?
            (?:
                (?<=分)
                (?<second>[〇一二三四五六七八九十]{1,3})秒
            )?
        )?
    /x;
    
    # 令和3年7月12日（月）
    # 令和3年7月12日（月）14時
    # 令和3年7月12日（月）14時7
    # 令和3年7月12日（月）14時7分
    # 令和3年7月12日（月）14時7分30秒
    # 令和3年7月12日
    # 令和3年7月12日14時
    # 令和3年7月12日14時7
    # 令和3年7月12日14時7分
    # 令和3年7月12日14時7分30秒
    # or
    # 2020年7月12日（月）
    # 2020年7月12日（月）14時
    # 2020年7月12日（月）14時7
    # 2020年7月12日（月）14時7分
    # 2020年7月12日（月）14時7分30秒
    # 2020年7月12日
    # 2020年7月12日14時
    # 2020年7月12日14時7
    # 2020年7月12日14時7分
    # 2020年7月12日14時7分30秒
    $DATETIME_PATTERN_1_RE = qr/
        ^[[:blank:]\h]*
        (?:
            (?:
                (?<era>[\p{Han}]+)
                (?<year>\d{1,2})
            )
            |
            (?<gregorian_year>\d{1,4})
        )年
        (?<month>\d{1,2})月
        (?<day>\d{1,2})日
        (?:[\(（]?(?<dow>$WEEKDAYS_RE)[\)）]?)?
        (?:
            $TIME_RE
        )?
        [[:blank:]\h]*$
    /x;
    # Same as pattern No 1, but using double bytes (Japanese) numbers
    $DATETIME_PATTERN_2_RE = qr/
        ^[[:blank:]\h]*
        (?:
            (?:
                (?<era>[\p{Han}]+)
                (?<year>[０１２３４５６７８９]{1,2})
            )
            |
            (?<gregorian_year>\d{1,4})
        )年
        (?<month>[０１２３４５６７８９]{1,2})月
        (?<day>[０１２３４５６７８９]{1,2})日
        (?:[\(（]?(?<dow>$WEEKDAYS_RE)[\)）]?)?
        (?:
            $TIME_ZENKAKU_RE
        )?
        [[:blank:]\h]*$
    /x;
    # Same as pattern No 1, but using Kanji numbers
    $DATETIME_PATTERN_3_RE = qr/
        ^[[:blank:]\h]*
        (?:
            (?:
                (?=[\p{Han}]+)
                (?<era>[^〇一二三四五六七八九十百千]+)
                # 三, 三十二
                (?<year>[〇一二三四五六七八九十]{1,3})
            )
            |
            # 二千三百四十八
            (?<gregorian_year>[〇一二三四五六七八九十百千]{1,7})
        )年
        (?<month>[〇一二三四五六七八九十]{1,2})月
        (?<day>[〇一二三四五六七八九十]{1,2})日
        (?:[\(（]?(?<dow>$WEEKDAYS_RE)[\)）]?)?
        (?:
            $TIME_KANJI_RE
        )?
        [[:blank:]\h]*$
    /x;
    
    $DICT = 
    [
        { name => '大化', period => '飛鳥時代', reading => ['たいか'], start => [645,7,17], end => [650,3,22] }, # 6年 from 645/7/17 until 650/3/22
        { name => '白雉', period => '飛鳥時代', reading => ['はくち','びゃくち','しらきぎす'], start => [650,3,22], end => [654,11,24] }, # 5年 from 650/3/22 until 654/11/24
        { name => '', period => '飛鳥時代', reading => [''], start => [654,11,24], end => [686,8,14] }, # 32年 from 654/11/24 until 686/8/14
        { name => '朱鳥', period => '飛鳥時代', reading => ['しゅちょう','すちょう','あかみとり'], start => [686,8,14], end => [686,10,1] }, # 1年 from 686/8/14 until 686/10/1
        { name => '', period => '飛鳥時代', reading => [''], start => [686,10,1], end => [701,5,3] }, # 15年 from 686/10/1 until 701/5/3
        { name => '大宝', period => '飛鳥時代', reading => ['たいほう','だいほう'], start => [701,5,3], end => [704,6,16] }, # 4年 from 701/5/3 until 704/6/16
        { name => '慶雲', period => '飛鳥時代', reading => ['けいうん','きょううん'], start => [704,6,16], end => [708,2,7] }, # 5年 from 704/6/16 until 708/2/7
        { name => '和銅', period => '飛鳥時代', reading => ['わどう'], start => [708,2,7], end => [715,10,3] }, # 8年 from 708/2/7 until 715/10/3
        { name => '霊亀', period => '奈良時代', reading => ['れいき'], start => [715,10,3], end => [717,12,24] }, # 3年 from 715/10/3 until 717/12/24
        { name => '養老', period => '奈良時代', reading => ['ようろう'], start => [717,12,24], end => [724,3,3] }, # 8年 from 717/12/24 until 724/3/3
        { name => '神亀', period => '奈良時代', reading => ['じんき'], start => [724,3,3], end => [729,9,2] }, # 6年 from 724/3/3 until 729/9/2
        { name => '天平', period => '奈良時代', reading => ['てんぴょう'], start => [729,9,2], end => [749,5,4] }, # 21年 from 729/9/2 until 749/5/4
        { name => '天平感宝', period => '奈良時代', reading => ['てんぴょうかんぽう'], start => [749,5,4], end => [749,8,19] }, # 1年 from 749/5/4 until 749/8/19
        { name => '天平勝宝', period => '奈良時代', reading => ['てんぴょうしょうほう'], start => [749,8,19], end => [757,9,6] }, # 9年 from 749/8/19 until 757/9/6
        { name => '天平宝字', period => '奈良時代', reading => ['てんぴょうほうじ'], start => [757,9,6], end => [765,2,1] }, # 9年 from 757/9/6 until 765/2/1
        { name => '天平神護', period => '奈良時代', reading => ['てんぴょうじんご'], start => [765,2,1], end => [767,9,13] }, # 3年 from 765/2/1 until 767/9/13
        { name => '神護景雲', period => '奈良時代', reading => ['じんごけいうん'], start => [767,9,13], end => [770,10,23] }, # 4年 from 767/9/13 until 770/10/23
        { name => '宝亀', period => '奈良時代', reading => ['ほうき'], start => [770,10,23], end => [781,1,30] }, # 12年 from 770/10/23 until 781/1/30
        { name => '天応', period => '奈良時代', reading => ['てんおう','てんのう'], start => [781,1,30], end => [782,9,30] }, # 2年 from 781/1/30 until 782/9/30
        { name => '延暦', period => '奈良時代', reading => ['えんりゃく'], start => [782,9,30], end => [806,6,8] }, # 25年 from 782/9/30 until 806/6/8
        { name => '大同', period => '平安時代', reading => ['だいどう'], start => [806,6,8], end => [810,10,20] }, # 5年 from 806/6/8 until 810/10/20
        { name => '弘仁', period => '平安時代', reading => ['こうにん'], start => [810,10,20], end => [824,2,8] }, # 15年 from 810/10/20 until 824/2/8
        { name => '天長', period => '平安時代', reading => ['てんちょう'], start => [824,2,8], end => [834,2,14] }, # 11年 from 824/2/8 until 834/2/14
        { name => '承和', period => '平安時代', reading => ['じょうわ','しょうわ'], start => [834,2,14], end => [848,7,16] }, # 15年 from 834/2/14 until 848/7/16
        { name => '嘉祥', period => '平安時代', reading => ['かしょう','かじょう'], start => [848,7,16], end => [851,6,1] }, # 4年 from 848/7/16 until 851/6/1
        { name => '仁寿', period => '平安時代', reading => ['にんじゅ'], start => [851,6,1], end => [854,12,23] }, # 4年 from 851/6/1 until 854/12/23
        { name => '斉衡', period => '平安時代', reading => ['さいこう'], start => [854,12,23], end => [857,3,20] }, # 4年 from 854/12/23 until 857/3/20
        { name => '天安', period => '平安時代', reading => ['てんあん','てんなん'], start => [857,3,20], end => [859,5,20] }, # 3年 from 857/3/20 until 859/5/20
        { name => '貞観', period => '平安時代', reading => ['じょうがん'], start => [859,5,20], end => [877,6,1] }, # 19年 from 859/5/20 until 877/6/1
        { name => '元慶', period => '平安時代', reading => ['がんぎょう'], start => [877,6,1], end => [885,3,11] }, # 9年 from 877/6/1 until 885/3/11
        { name => '仁和', period => '平安時代', reading => ['にんな','にんわ'], start => [885,3,11], end => [889,5,30] }, # 5年 from 885/3/11 until 889/5/30
        { name => '寛平', period => '平安時代', reading => ['かんぴょう','かんぺい','かんへい'], start => [889,5,30], end => [898,5,20] }, # 10年 from 889/5/30 until 898/5/20
        { name => '昌泰', period => '平安時代', reading => ['しょうたい'], start => [898,5,20], end => [901,8,31] }, # 4年 from 898/5/20 until 901/8/31
        { name => '延喜', period => '平安時代', reading => ['えんぎ'], start => [901,8,31], end => [923,5,29] }, # 23年 from 901/8/31 until 923/5/29
        { name => '延長', period => '平安時代', reading => ['えんちょう'], start => [923,5,29], end => [931,5,16] }, # 9年 from 923/5/29 until 931/5/16
        { name => '承平', period => '平安時代', reading => ['じょうへい','しょうへい'], start => [931,5,16], end => [938,6,22] }, # 8年 from 931/5/16 until 938/6/22
        { name => '天慶', period => '平安時代', reading => ['てんぎょう','てんきょう'], start => [938,6,22], end => [947,5,15] }, # 10年 from 938/6/22 until 947/5/15
        { name => '天暦', period => '平安時代', reading => ['てんりゃく'], start => [947,5,15], end => [957,11,21] }, # 11年 from 947/5/15 until 957/11/21
        { name => '天徳', period => '平安時代', reading => ['てんとく'], start => [957,11,21], end => [961,3,5] }, # 5年 from 957/11/21 until 961/3/5
        { name => '応和', period => '平安時代', reading => ['おうわ'], start => [961,3,5], end => [964,8,19] }, # 4年 from 961/3/5 until 964/8/19
        { name => '康保', period => '平安時代', reading => ['こうほう'], start => [964,8,19], end => [968,9,8] }, # 5年 from 964/8/19 until 968/9/8
        { name => '安和', period => '平安時代', reading => ['あんな','あんわ'], start => [968,9,8], end => [970,5,3] }, # 3年 from 968/9/8 until 970/5/3
        { name => '天禄', period => '平安時代', reading => ['てんろく'], start => [970,5,3], end => [974,1,16] }, # 4年 from 970/5/3 until 974/1/16
        { name => '天延', period => '平安時代', reading => ['てんえん'], start => [974,1,16], end => [976,8,11] }, # 4年 from 974/1/16 until 976/8/11
        { name => '貞元', period => '平安時代', reading => ['じょうげん'], start => [976,8,11], end => [978,12,31] }, # 3年 from 976/8/11 until 978/12/31
        { name => '天元', period => '平安時代', reading => ['てんげん'], start => [978,12,31], end => [983,5,29] }, # 6年 from 978/12/31 until 983/5/29
        { name => '永観', period => '平安時代', reading => ['えいかん'], start => [983,5,29], end => [985,5,19] }, # 3年 from 983/5/29 until 985/5/19
        { name => '寛和', period => '平安時代', reading => ['かんな','かんわ'], start => [985,5,19], end => [987,5,5] }, # 3年 from 985/5/19 until 987/5/5
        { name => '永延', period => '平安時代', reading => ['えいえん'], start => [987,5,5], end => [989,9,10] }, # 3年 from 987/5/5 until 989/9/10
        { name => '永祚', period => '平安時代', reading => ['えいそ'], start => [989,9,10], end => [990,11,26] }, # 2年 from 989/9/10 until 990/11/26
        { name => '正暦', period => '平安時代', reading => ['しょうりゃく'], start => [990,11,26], end => [995,3,25] }, # 6年 from 990/11/26 until 995/3/25
        { name => '長徳', period => '平安時代', reading => ['ちょうとく'], start => [995,3,25], end => [999,2,1] }, # 5年 from 995/3/25 until 999/2/1
        { name => '長保', period => '平安時代', reading => ['ちょうほう'], start => [999,2,1], end => [1004,8,8] }, # 6年 from 999/2/1 until 1004/8/8
        { name => '寛弘', period => '平安時代', reading => ['かんこう'], start => [1004,8,8], end => [1013,2,8] }, # 9年 from 1004/8/8 until 1013/2/8
        { name => '長和', period => '平安時代', reading => ['ちょうわ'], start => [1013,2,8], end => [1017,5,21] }, # 6年 from 1013/2/8 until 1017/5/21
        { name => '寛仁', period => '平安時代', reading => ['かんにん'], start => [1017,5,21], end => [1021,3,17] }, # 5年 from 1017/5/21 until 1021/3/17
        { name => '治安', period => '平安時代', reading => ['じあん'], start => [1021,3,17], end => [1024,8,19] }, # 4年 from 1021/3/17 until 1024/8/19
        { name => '万寿', period => '平安時代', reading => ['まんじゅ'], start => [1024,8,19], end => [1028,8,18] }, # 5年 from 1024/8/19 until 1028/8/18
        { name => '長元', period => '平安時代', reading => ['ちょうげん'], start => [1028,8,18], end => [1037,5,9] }, # 10年 from 1028/8/18 until 1037/5/9
        { name => '長暦', period => '平安時代', reading => ['ちょうりゃく'], start => [1037,5,9], end => [1040,12,16] }, # 4年 from 1037/5/9 until 1040/12/16
        { name => '長久', period => '平安時代', reading => ['ちょうきゅう'], start => [1040,12,16], end => [1044,12,16] }, # 5年 from 1040/12/16 until 1044/12/16
        { name => '寛徳', period => '平安時代', reading => ['かんとく'], start => [1044,12,16], end => [1046,5,22] }, # 3年 from 1044/12/16 until 1046/5/22
        { name => '永承', period => '平安時代', reading => ['えいしょう','えいじょう'], start => [1046,5,22], end => [1053,2,2] }, # 8年 from 1046/5/22 until 1053/2/2
        { name => '天喜', period => '平安時代', reading => ['てんぎ','てんき'], start => [1053,2,2], end => [1058,9,19] }, # 6年 from 1053/2/2 until 1058/9/19
        { name => '康平', period => '平安時代', reading => ['こうへい'], start => [1058,9,19], end => [1065,9,4] }, # 8年 from 1058/9/19 until 1065/9/4
        { name => '治暦', period => '平安時代', reading => ['じりゃく'], start => [1065,9,4], end => [1069,5,6] }, # 5年 from 1065/9/4 until 1069/5/6
        { name => '延久', period => '平安時代', reading => ['えんきゅう'], start => [1069,5,6], end => [1074,9,16] }, # 6年 from 1069/5/6 until 1074/9/16
        { name => '承保', period => '平安時代', reading => ['じょうほう','しょうほう'], start => [1074,9,16], end => [1077,12,5] }, # 4年 from 1074/9/16 until 1077/12/5
        { name => '承暦', period => '平安時代', reading => ['じょうりゃく','しょうりゃく'], start => [1077,12,5], end => [1081,3,22] }, # 5年 from 1077/12/5 until 1081/3/22
        { name => '永保', period => '平安時代', reading => ['えいほう'], start => [1081,3,22], end => [1084,3,15] }, # 4年 from 1081/3/22 until 1084/3/15
        { name => '応徳', period => '平安時代', reading => ['おうとく'], start => [1084,3,15], end => [1087,5,11] }, # 4年 from 1084/3/15 until 1087/5/11
        { name => '寛治', period => '平安時代', reading => ['かんじ'], start => [1087,5,11], end => [1095,1,23] }, # 8年 from 1087/5/11 until 1095/1/23
        { name => '嘉保', period => '平安時代', reading => ['かほう'], start => [1095,1,23], end => [1097,1,3] }, # 3年 from 1095/1/23 until 1097/1/3
        { name => '永長', period => '平安時代', reading => ['えいちょう'], start => [1097,1,3], end => [1097,12,27] }, # 2年 from 1097/1/3 until 1097/12/27
        { name => '承徳', period => '平安時代', reading => ['じょうとく','しょうとく'], start => [1097,12,27], end => [1099,9,15] }, # 3年 from 1097/12/27 until 1099/9/15
        { name => '康和', period => '平安時代', reading => ['こうわ'], start => [1099,9,15], end => [1104,3,8] }, # 6年 from 1099/9/15 until 1104/3/8
        { name => '長治', period => '平安時代', reading => ['ちょうじ'], start => [1104,3,8], end => [1106,5,13] }, # 3年 from 1104/3/8 until 1106/5/13
        { name => '嘉承', period => '平安時代', reading => ['かしょう','かじょう'], start => [1106,5,13], end => [1108,9,9] }, # 3年 from 1106/5/13 until 1108/9/9
        { name => '天仁', period => '平安時代', reading => ['てんにん'], start => [1108,9,9], end => [1110,7,31] }, # 3年 from 1108/9/9 until 1110/7/31
        { name => '天永', period => '平安時代', reading => ['てんえい'], start => [1110,7,31], end => [1113,8,25] }, # 4年 from 1110/7/31 until 1113/8/25
        { name => '永久', period => '平安時代', reading => ['えいきゅう'], start => [1113,8,25], end => [1118,4,25] }, # 6年 from 1113/8/25 until 1118/4/25
        { name => '元永', period => '平安時代', reading => ['げんえい'], start => [1118,4,25], end => [1120,5,9] }, # 3年 from 1118/4/25 until 1120/5/9
        { name => '保安', period => '平安時代', reading => ['ほうあん'], start => [1120,5,9], end => [1124,5,18] }, # 5年 from 1120/5/9 until 1124/5/18
        { name => '天治', period => '平安時代', reading => ['てんじ'], start => [1124,5,18], end => [1126,2,15] }, # 3年 from 1124/5/18 until 1126/2/15
        { name => '大治', period => '平安時代', reading => ['だいじ'], start => [1126,2,15], end => [1131,2,28] }, # 6年 from 1126/2/15 until 1131/2/28
        { name => '天承', period => '平安時代', reading => ['てんしょう','てんじょう'], start => [1131,2,28], end => [1132,9,21] }, # 2年 from 1131/2/28 until 1132/9/21
        { name => '長承', period => '平安時代', reading => ['ちょうしょう'], start => [1132,9,21], end => [1135,6,10] }, # 4年 from 1132/9/21 until 1135/6/10
        { name => '保延', period => '平安時代', reading => ['ほうえん'], start => [1135,6,10], end => [1141,8,13] }, # 7年 from 1135/6/10 until 1141/8/13
        { name => '永治', period => '平安時代', reading => ['えいじ'], start => [1141,8,13], end => [1142,5,25] }, # 2年 from 1141/8/13 until 1142/5/25
        { name => '康治', period => '平安時代', reading => ['こうじ'], start => [1142,5,25], end => [1144,3,28] }, # 3年 from 1142/5/25 until 1144/3/28
        { name => '天養', period => '平安時代', reading => ['てんよう'], start => [1144,3,28], end => [1145,8,12] }, # 2年 from 1144/3/28 until 1145/8/12
        { name => '久安', period => '平安時代', reading => ['きゅうあん'], start => [1145,8,12], end => [1151,2,14] }, # 7年 from 1145/8/12 until 1151/2/14
        { name => '仁平', period => '平安時代', reading => ['にんぺい','にんぴょう'], start => [1151,2,14], end => [1154,12,4] }, # 4年 from 1151/2/14 until 1154/12/4
        { name => '久寿', period => '平安時代', reading => ['きゅうじゅ'], start => [1154,12,4], end => [1156,5,18] }, # 3年 from 1154/12/4 until 1156/5/18
        { name => '保元', period => '平安時代', reading => ['ほうげん'], start => [1156,5,18], end => [1159,5,9] }, # 4年 from 1156/5/18 until 1159/5/9
        { name => '平治', period => '平安時代', reading => ['へいじ'], start => [1159,5,9], end => [1160,2,18] }, # 2年 from 1159/5/9 until 1160/2/18
        { name => '永暦', period => '平安時代', reading => ['えいりゃく'], start => [1160,2,18], end => [1161,9,24] }, # 2年 from 1160/2/18 until 1161/9/24
        { name => '応保', period => '平安時代', reading => ['おうほう','おうほ'], start => [1161,9,24], end => [1163,5,4] }, # 3年 from 1161/9/24 until 1163/5/4
        { name => '長寛', period => '平安時代', reading => ['ちょうかん'], start => [1163,5,4], end => [1165,7,14] }, # 3年 from 1163/5/4 until 1165/7/14
        { name => '永万', period => '平安時代', reading => ['えいまん'], start => [1165,7,14], end => [1166,9,23] }, # 2年 from 1165/7/14 until 1166/9/23
        { name => '仁安', period => '平安時代', reading => ['にんあん'], start => [1166,9,23], end => [1169,5,6] }, # 4年 from 1166/9/23 until 1169/5/6
        { name => '嘉応', period => '平安時代', reading => ['かおう'], start => [1169,5,6], end => [1171,5,27] }, # 3年 from 1169/5/6 until 1171/5/27
        { name => '承安', period => '平安時代', reading => ['じょうあん'], start => [1171,5,27], end => [1175,8,16] }, # 5年 from 1171/5/27 until 1175/8/16
        { name => '安元', period => '平安時代', reading => ['あんげん'], start => [1175,8,16], end => [1177,8,29] }, # 3年 from 1175/8/16 until 1177/8/29
        { name => '治承', period => '平安時代', reading => ['じしょう'], start => [1177,8,29], end => [1181,8,25] }, # 5年 from 1177/8/29 until 1181/8/25
        { name => '養和', period => '平安時代', reading => ['ようわ'], start => [1181,8,25], end => [1182,6,29] }, # 2年 from 1181/8/25 until 1182/6/29
        { name => '寿永', period => '平安時代', reading => ['じゅえい'], start => [1182,6,29], end => [1184,5,27] }, # 3年 from 1182/6/29 until 1184/5/27
        { name => '元暦', period => '平安時代', reading => ['げんりゃく'], start => [1184,5,27], end => [1185,9,9] }, # 2年 from 1184/5/27 until 1185/9/9
        { name => '文治', period => '鎌倉時代', reading => ['ぶんじ'], start => [1185,9,9], end => [1190,5,16] }, # 6年 from 1185/9/9 until 1190/5/16
        { name => '建久', period => '鎌倉時代', reading => ['けんきゅう'], start => [1190,5,16], end => [1199,5,23] }, # 10年 from 1190/5/16 until 1199/5/23
        { name => '正治', period => '鎌倉時代', reading => ['しょうじ'], start => [1199,5,23], end => [1201,3,19] }, # 3年 from 1199/5/23 until 1201/3/19
        { name => '建仁', period => '鎌倉時代', reading => ['けんにん'], start => [1201,3,19], end => [1204,3,23] }, # 4年 from 1201/3/19 until 1204/3/23
        { name => '元久', period => '鎌倉時代', reading => ['げんきゅう'], start => [1204,3,23], end => [1206,6,5] }, # 3年 from 1204/3/23 until 1206/6/5
        { name => '建永', period => '鎌倉時代', reading => ['けんえい'], start => [1206,6,5], end => [1207,11,16] }, # 2年 from 1206/6/5 until 1207/11/16
        { name => '承元', period => '鎌倉時代', reading => ['じょうげん'], start => [1207,11,16], end => [1211,4,23] }, # 5年 from 1207/11/16 until 1211/4/23
        { name => '建暦', period => '鎌倉時代', reading => ['けんりゃく'], start => [1211,4,23], end => [1214,1,18] }, # 3年 from 1211/4/23 until 1214/1/18
        { name => '建保', period => '鎌倉時代', reading => ['けんぽう'], start => [1214,1,18], end => [1219,5,27] }, # 7年 from 1214/1/18 until 1219/5/27
        { name => '承久', period => '鎌倉時代', reading => ['じょうきゅう'], start => [1219,5,27], end => [1222,5,25] }, # 4年 from 1219/5/27 until 1222/5/25
        { name => '貞応', period => '鎌倉時代', reading => ['じょうおう'], start => [1222,5,25], end => [1224,12,31] }, # 3年 from 1222/5/25 until 1224/12/31
        { name => '元仁', period => '鎌倉時代', reading => ['げんにん'], start => [1224,12,31], end => [1225,5,28] }, # 2年 from 1224/12/31 until 1225/5/28
        { name => '嘉禄', period => '鎌倉時代', reading => ['かろく'], start => [1225,5,28], end => [1228,1,18] }, # 3年 from 1225/5/28 until 1228/1/18
        { name => '安貞', period => '鎌倉時代', reading => ['あんてい'], start => [1228,1,18], end => [1229,3,31] }, # 3年 from 1228/1/18 until 1229/3/31
        { name => '寛喜', period => '鎌倉時代', reading => ['かんぎ'], start => [1229,3,31], end => [1232,4,23] }, # 4年 from 1229/3/31 until 1232/4/23
        { name => '貞永', period => '鎌倉時代', reading => ['じょうえい'], start => [1232,4,23], end => [1233,5,25] }, # 2年 from 1232/4/23 until 1233/5/25
        { name => '天福', period => '鎌倉時代', reading => ['てんぷく'], start => [1233,5,25], end => [1234,11,27] }, # 2年 from 1233/5/25 until 1234/11/27
        { name => '文暦', period => '鎌倉時代', reading => ['ぶんりゃく'], start => [1234,11,27], end => [1235,11,1] }, # 2年 from 1234/11/27 until 1235/11/1
        { name => '嘉禎', period => '鎌倉時代', reading => ['かてい'], start => [1235,11,1], end => [1238,12,30] }, # 4年 from 1235/11/1 until 1238/12/30
        { name => '暦仁', period => '鎌倉時代', reading => ['りゃくにん'], start => [1238,12,30], end => [1239,3,13] }, # 2年 from 1238/12/30 until 1239/3/13
        { name => '延応', period => '鎌倉時代', reading => ['えんおう'], start => [1239,3,13], end => [1240,8,5] }, # 2年 from 1239/3/13 until 1240/8/5
        { name => '仁治', period => '鎌倉時代', reading => ['にんじ'], start => [1240,8,5], end => [1243,3,18] }, # 4年 from 1240/8/5 until 1243/3/18
        { name => '寛元', period => '鎌倉時代', reading => ['かんげん'], start => [1243,3,18], end => [1247,4,5] }, # 5年 from 1243/3/18 until 1247/4/5
        { name => '宝治', period => '鎌倉時代', reading => ['ほうじ'], start => [1247,4,5], end => [1249,5,2] }, # 3年 from 1247/4/5 until 1249/5/2
        { name => '建長', period => '鎌倉時代', reading => ['けんちょう'], start => [1249,5,2], end => [1256,10,24] }, # 8年 from 1249/5/2 until 1256/10/24
        { name => '康元', period => '鎌倉時代', reading => ['こうげん'], start => [1256,10,24], end => [1257,3,31] }, # 2年 from 1256/10/24 until 1257/3/31
        { name => '正嘉', period => '鎌倉時代', reading => ['しょうか'], start => [1257,3,31], end => [1259,4,20] }, # 3年 from 1257/3/31 until 1259/4/20
        { name => '正元', period => '鎌倉時代', reading => ['しょうげん'], start => [1259,4,20], end => [1260,5,24] }, # 2年 from 1259/4/20 until 1260/5/24
        { name => '文応', period => '鎌倉時代', reading => ['ぶんおう'], start => [1260,5,24], end => [1261,3,22] }, # 2年 from 1260/5/24 until 1261/3/22
        { name => '弘長', period => '鎌倉時代', reading => ['こうちょう'], start => [1261,3,22], end => [1264,3,27] }, # 4年 from 1261/3/22 until 1264/3/27
        { name => '文永', period => '鎌倉時代', reading => ['ぶんえい'], start => [1264,3,27], end => [1275,5,22] }, # 12年 from 1264/3/27 until 1275/5/22
        { name => '建治', period => '鎌倉時代', reading => ['けんじ'], start => [1275,5,22], end => [1278,3,23] }, # 4年 from 1275/5/22 until 1278/3/23
        { name => '弘安', period => '鎌倉時代', reading => ['こうあん'], start => [1278,3,23], end => [1288,5,29] }, # 11年 from 1278/3/23 until 1288/5/29
        { name => '正応', period => '鎌倉時代', reading => ['しょうおう'], start => [1288,5,29], end => [1293,9,6] }, # 6年 from 1288/5/29 until 1293/9/6
        { name => '永仁', period => '鎌倉時代', reading => ['えいにん'], start => [1293,9,6], end => [1299,5,25] }, # 7年 from 1293/9/6 until 1299/5/25
        { name => '正安', period => '鎌倉時代', reading => ['しょうあん'], start => [1299,5,25], end => [1302,12,10] }, # 4年 from 1299/5/25 until 1302/12/10
        { name => '乾元', period => '鎌倉時代', reading => ['けんげん'], start => [1302,12,10], end => [1303,9,16] }, # 2年 from 1302/12/10 until 1303/9/16
        { name => '嘉元', period => '鎌倉時代', reading => ['かげん'], start => [1303,9,16], end => [1307,1,18] }, # 4年 from 1303/9/16 until 1307/1/18
        { name => '徳治', period => '鎌倉時代', reading => ['とくじ'], start => [1307,1,18], end => [1308,11,22] }, # 3年 from 1307/1/18 until 1308/11/22
        { name => '延慶', period => '鎌倉時代', reading => ['えんきょう'], start => [1308,11,22], end => [1311,5,17] }, # 4年 from 1308/11/22 until 1311/5/17
        { name => '応長', period => '鎌倉時代', reading => ['おうちょう'], start => [1311,5,17], end => [1312,4,27] }, # 2年 from 1311/5/17 until 1312/4/27
        { name => '正和', period => '鎌倉時代', reading => ['しょうわ'], start => [1312,4,27], end => [1317,3,16] }, # 6年 from 1312/4/27 until 1317/3/16
        { name => '文保', period => '鎌倉時代', reading => ['ぶんぽう'], start => [1317,3,16], end => [1319,5,18] }, # 3年 from 1317/3/16 until 1319/5/18
        { name => '元応', period => '鎌倉時代', reading => ['げんおう'], start => [1319,5,18], end => [1321,3,22] }, # 3年 from 1319/5/18 until 1321/3/22
        { name => '元亨', period => '鎌倉時代', reading => ['げんこう'], start => [1321,3,22], end => [1324,12,25] }, # 4年 from 1321/3/22 until 1324/12/25
        { name => '正中', period => '鎌倉時代', reading => ['しょうちゅう'], start => [1324,12,25], end => [1326,5,28] }, # 3年 from 1324/12/25 until 1326/5/28
        { name => '嘉暦', period => '鎌倉時代', reading => ['かりゃく'], start => [1326,5,28], end => [1329,9,22] }, # 4年 from 1326/5/28 until 1329/9/22
        { name => '元徳', period => '鎌倉時代', reading => ['げんとく'], start => [1329,9,22], end => [1331,9,11] }, # 3年 from 1329/9/22 until 1331/9/11
        { name => '元弘', period => '大覚寺統', reading => ['げんこう'], start => [1331,9,11], end => [1334,3,5] }, # 4年 from 1331/9/11 until 1334/3/5
        { name => '正慶', period => '持明院統', reading => ['しょうけい','しょうきょう'], start => [1332,5,23], end => [1333,7,7] }, # 2年 from 1332/5/23 until 1333/7/7
        { name => '建武', period => '南北朝時代・室町時代', reading => [''], start => [1334,3,5], end => [1338,10,11] }, # 3年 from 1334/3/5 until 1338/10/11
        { name => '暦応', period => '北朝（持明院統）', reading => ['りゃくおう','れきおう'], start => [1338,10,11], end => [1342,6,1] }, # 5年 from 1338/10/11 until 1342/6/1
        { name => '康永', period => '北朝（持明院統）', reading => ['こうえい'], start => [1342,6,1], end => [1345,11,15] }, # 4年 from 1342/6/1 until 1345/11/15
        { name => '貞和', period => '北朝（持明院統）', reading => ['じょうわ','ていわ'], start => [1345,11,15], end => [1350,4,4] }, # 6年 from 1345/11/15 until 1350/4/4
        { name => '観応', period => '北朝（持明院統）', reading => ['かんのう','かんおう'], start => [1350,4,4], end => [1352,11,4] }, # 3年 from 1350/4/4 until 1352/11/4
        { name => '文和', period => '北朝（持明院統）', reading => ['ぶんな','ぶんわ'], start => [1352,11,4], end => [1356,4,29] }, # 5年 from 1352/11/4 until 1356/4/29
        { name => '延文', period => '北朝（持明院統）', reading => ['えんぶん'], start => [1356,4,29], end => [1361,5,4] }, # 6年 from 1356/4/29 until 1361/5/4
        { name => '康安', period => '北朝（持明院統）', reading => ['こうあん'], start => [1361,5,4], end => [1362,10,11] }, # 2年 from 1361/5/4 until 1362/10/11
        { name => '貞治', period => '北朝（持明院統）', reading => ['じょうじ','ていじ'], start => [1362,10,11], end => [1368,3,7] }, # 7年 from 1362/10/11 until 1368/3/7
        { name => '応安', period => '北朝（持明院統）', reading => ['おうあん'], start => [1368,3,7], end => [1375,3,29] }, # 8年 from 1368/3/7 until 1375/3/29
        { name => '永和', period => '北朝（持明院統）', reading => ['えいわ'], start => [1375,3,29], end => [1379,4,9] }, # 5年 from 1375/3/29 until 1379/4/9
        { name => '康暦', period => '北朝（持明院統）', reading => ['こうりゃく'], start => [1379,4,9], end => [1381,3,20] }, # 3年 from 1379/4/9 until 1381/3/20
        { name => '永徳', period => '北朝（持明院統）', reading => ['えいとく'], start => [1381,3,20], end => [1384,3,19] }, # 4年 from 1381/3/20 until 1384/3/19
        { name => '至徳', period => '北朝（持明院統）', reading => ['しとく'], start => [1384,3,19], end => [1387,10,5] }, # 4年 from 1384/3/19 until 1387/10/5
        { name => '嘉慶', period => '北朝（持明院統）', reading => ['かけい','かきょう'], start => [1387,10,5], end => [1389,3,7] }, # 3年 from 1387/10/5 until 1389/3/7
        { name => '康応', period => '北朝（持明院統）', reading => ['こうおう'], start => [1389,3,7], end => [1390,4,12] }, # 2年 from 1389/3/7 until 1390/4/12
        { name => '明徳', period => '北朝（持明院統）', reading => ['めいとく'], start => [1390,4,12], end => [1394,8,2] }, # 5年 from 1390/4/12 until 1394/8/2
        { name => '応永', period => '南北朝合一後', reading => ['おうえい'], start => [1394,8,2], end => [1428,6,10] }, # 35年 from 1394/8/2 until 1428/6/10
        { name => '正長', period => '南北朝合一後', reading => ['しょうちょう'], start => [1428,6,10], end => [1429,10,3] }, # 2年 from 1428/6/10 until 1429/10/3
        { name => '永享', period => '南北朝合一後', reading => ['えいきょう'], start => [1429,10,3], end => [1441,3,10] }, # 13年 from 1429/10/3 until 1441/3/10
        { name => '嘉吉', period => '南北朝合一後', reading => ['かきつ'], start => [1441,3,10], end => [1444,2,23] }, # 4年 from 1441/3/10 until 1444/2/23
        { name => '文安', period => '南北朝合一後', reading => ['ぶんあん'], start => [1444,2,23], end => [1449,8,16] }, # 6年 from 1444/2/23 until 1449/8/16
        { name => '宝徳', period => '南北朝合一後', reading => ['ほうとく'], start => [1449,8,16], end => [1452,8,10] }, # 4年 from 1449/8/16 until 1452/8/10
        { name => '享徳', period => '南北朝合一後', reading => ['きょうとく'], start => [1452,8,10], end => [1455,9,6] }, # 4年 from 1452/8/10 until 1455/9/6
        { name => '康正', period => '南北朝合一後', reading => ['こうしょう'], start => [1455,9,6], end => [1457,10,16] }, # 3年 from 1455/9/6 until 1457/10/16
        { name => '長禄', period => '南北朝合一後', reading => ['ちょうろく'], start => [1457,10,16], end => [1461,2,1] }, # 4年 from 1457/10/16 until 1461/2/1
        { name => '寛正', period => '南北朝合一後', reading => ['かんしょう'], start => [1461,2,1], end => [1466,3,14] }, # 7年 from 1461/2/1 until 1466/3/14
        { name => '文正', period => '南北朝合一後', reading => ['ぶんしょう'], start => [1466,3,14], end => [1467,4,9] }, # 2年 from 1466/3/14 until 1467/4/9
        { name => '応仁', period => '戦国時代', reading => ['おうにん'], start => [1467,4,9], end => [1469,6,8] }, # 3年 from 1467/4/9 until 1469/6/8
        { name => '文明', period => '戦国時代', reading => ['ぶんめい'], start => [1469,6,8], end => [1487,8,9] }, # 19年 from 1469/6/8 until 1487/8/9
        { name => '長享', period => '戦国時代', reading => ['ちょうきょう'], start => [1487,8,9], end => [1489,9,16] }, # 3年 from 1487/8/9 until 1489/9/16
        { name => '延徳', period => '戦国時代', reading => ['えんとく'], start => [1489,9,16], end => [1492,8,12] }, # 4年 from 1489/9/16 until 1492/8/12
        { name => '明応', period => '戦国時代', reading => ['めいおう'], start => [1492,8,12], end => [1501,3,18] }, # 10年 from 1492/8/12 until 1501/3/18
        { name => '文亀', period => '戦国時代', reading => ['ぶんき'], start => [1501,3,18], end => [1504,3,16] }, # 4年 from 1501/3/18 until 1504/3/16
        { name => '永正', period => '戦国時代', reading => ['えいしょう'], start => [1504,3,16], end => [1521,9,23] }, # 18年 from 1504/3/16 until 1521/9/23
        { name => '大永', period => '戦国時代', reading => ['たいえい'], start => [1521,9,23], end => [1528,9,3] }, # 8年 from 1521/9/23 until 1528/9/3
        { name => '享禄', period => '戦国時代', reading => ['きょうろく'], start => [1528,9,3], end => [1532,8,29] }, # 5年 from 1528/9/3 until 1532/8/29
        { name => '天文', period => '戦国時代', reading => ['てんぶん'], start => [1532,8,29], end => [1555,11,7] }, # 24年 from 1532/8/29 until 1555/11/7
        { name => '弘治', period => '戦国時代', reading => ['こうじ'], start => [1555,11,7], end => [1558,3,18] }, # 4年 from 1555/11/7 until 1558/3/18
        { name => '永禄', period => '戦国時代', reading => ['えいろく'], start => [1558,3,18], end => [1570,5,27] }, # 13年 from 1558/3/18 until 1570/5/27
        { name => '元亀', period => '戦国時代', reading => ['げんき'], start => [1570,5,27], end => [1573,8,25] }, # 4年 from 1570/5/27 until 1573/8/25
        { name => '天正', period => '安土桃山時代', reading => ['てんしょう'], start => [1573,8,25], end => [1593,1,10] }, # 20年 from 1573/8/25 until 1593/1/10
        { name => '文禄', period => '安土桃山時代', reading => ['ぶんろく'], start => [1593,1,10], end => [1596,12,16] }, # 5年 from 1593/1/10 until 1596/12/16
        { name => '慶長', period => '安土桃山時代', reading => ['けいちょう'], start => [1596,12,16], end => [1615,9,5] }, # 20年 from 1596/12/16 until 1615/9/5
        { name => '元和', period => '江戸時代', reading => ['げんな'], start => [1615,9,5], end => [1624,4,17] }, # 10年 from 1615/9/5 until 1624/4/17
        { name => '寛永', period => '江戸時代', reading => ['かんえい'], start => [1624,4,17], end => [1645,1,13] }, # 21年 from 1624/4/17 until 1645/1/13
        { name => '正保', period => '江戸時代', reading => ['しょうほう'], start => [1645,1,13], end => [1648,4,7] }, # 5年 from 1645/1/13 until 1648/4/7
        { name => '慶安', period => '江戸時代', reading => ['けいあん'], start => [1648,4,7], end => [1652,10,20] }, # 5年 from 1648/4/7 until 1652/10/20
        { name => '承応', period => '江戸時代', reading => ['じょうおう'], start => [1652,10,20], end => [1655,5,18] }, # 4年 from 1652/10/20 until 1655/5/18
        { name => '明暦', period => '江戸時代', reading => ['めいれき'], start => [1655,5,18], end => [1658,8,21] }, # 4年 from 1655/5/18 until 1658/8/21
        { name => '万治', period => '江戸時代', reading => ['まんじ'], start => [1658,8,21], end => [1661,5,23] }, # 4年 from 1658/8/21 until 1661/5/23
        { name => '寛文', period => '江戸時代', reading => ['かんぶん'], start => [1661,5,23], end => [1673,10,30] }, # 13年 from 1661/5/23 until 1673/10/30
        { name => '延宝', period => '江戸時代', reading => ['えんぽう'], start => [1673,10,30], end => [1681,11,9] }, # 9年 from 1673/10/30 until 1681/11/9
        { name => '天和', period => '江戸時代', reading => ['てんな'], start => [1681,11,9], end => [1684,4,5] }, # 4年 from 1681/11/9 until 1684/4/5
        { name => '貞享', period => '江戸時代', reading => ['じょうきょう'], start => [1684,4,5], end => [1688,10,23] }, # 5年 from 1684/4/5 until 1688/10/23
        { name => '元禄', period => '江戸時代', reading => ['げんろく'], start => [1688,10,23], end => [1704,4,16] }, # 17年 from 1688/10/23 until 1704/4/16
        { name => '宝永', period => '江戸時代', reading => ['ほうえい'], start => [1704,4,16], end => [1711,6,11] }, # 8年 from 1704/4/16 until 1711/6/11
        { name => '正徳', period => '江戸時代', reading => ['しょうとく'], start => [1711,6,11], end => [1716,8,9] }, # 6年 from 1711/6/11 until 1716/8/9
        { name => '享保', period => '江戸時代', reading => ['きょうほう'], start => [1716,8,9], end => [1736,6,7] }, # 21年 from 1716/8/9 until 1736/6/7
        { name => '元文', period => '江戸時代', reading => ['げんぶん'], start => [1736,6,7], end => [1741,4,12] }, # 6年 from 1736/6/7 until 1741/4/12
        { name => '寛保', period => '江戸時代', reading => ['かんぽう'], start => [1741,4,12], end => [1744,4,3] }, # 4年 from 1741/4/12 until 1744/4/3
        { name => '延享', period => '江戸時代', reading => ['えんきょう'], start => [1744,4,3], end => [1748,8,5] }, # 5年 from 1744/4/3 until 1748/8/5
        { name => '寛延', period => '江戸時代', reading => ['かんえん'], start => [1748,8,5], end => [1751,12,14] }, # 4年 from 1748/8/5 until 1751/12/14
        { name => '宝暦', period => '江戸時代', reading => ['ほうれき'], start => [1751,12,14], end => [1764,6,30] }, # 14年 from 1751/12/14 until 1764/6/30
        { name => '明和', period => '江戸時代', reading => ['めいわ'], start => [1764,6,30], end => [1772,12,10] }, # 9年 from 1764/6/30 until 1772/12/10
        { name => '安永', period => '江戸時代', reading => ['あんえい'], start => [1772,12,10], end => [1781,4,25] }, # 10年 from 1772/12/10 until 1781/4/25
        { name => '天明', period => '江戸時代', reading => ['てんめい'], start => [1781,4,25], end => [1789,2,19] }, # 9年 from 1781/4/25 until 1789/2/19
        { name => '寛政', period => '江戸時代', reading => ['かんせい'], start => [1789,2,19], end => [1801,3,19] }, # 13年 from 1789/2/19 until 1801/3/19
        { name => '享和', period => '江戸時代', reading => ['きょうわ'], start => [1801,3,19], end => [1804,3,22] }, # 4年 from 1801/3/19 until 1804/3/22
        { name => '文化', period => '江戸時代', reading => ['ぶんか'], start => [1804,3,22], end => [1818,5,26] }, # 15年 from 1804/3/22 until 1818/5/26
        { name => '文政', period => '江戸時代', reading => ['ぶんせい'], start => [1818,5,26], end => [1831,1,23] }, # 13年 from 1818/5/26 until 1831/1/23
        { name => '天保', period => '江戸時代', reading => ['てんぽう'], start => [1831,1,23], end => [1845,1,9] }, # 15年 from 1831/1/23 until 1845/1/9
        { name => '弘化', period => '江戸時代', reading => ['こうか'], start => [1845,1,9], end => [1848,4,1] }, # 5年 from 1845/1/9 until 1848/4/1
        { name => '嘉永', period => '江戸時代', reading => ['かえい'], start => [1848,4,1], end => [1855,1,15] }, # 7年 from 1848/4/1 until 1855/1/15
        { name => '安政', period => '江戸時代', reading => ['あんせい'], start => [1855,1,15], end => [1860,4,8] }, # 7年 from 1855/1/15 until 1860/4/8
        { name => '万延', period => '江戸時代', reading => ['まんえん'], start => [1860,4,8], end => [1861,3,29] }, # 2年 from 1860/4/8 until 1861/3/29
        { name => '文久', period => '江戸時代', reading => ['ぶんきゅう'], start => [1861,3,29], end => [1864,3,27] }, # 4年 from 1861/3/29 until 1864/3/27
        { name => '元治', period => '江戸時代', reading => ['げんじ'], start => [1864,3,27], end => [1865,5,1] }, # 2年 from 1864/3/27 until 1865/5/1
        { name => '慶応', period => '江戸時代', reading => ['けいおう'], start => [1865,5,1], end => [1868,10,23] }, # 4年 from 1865/5/1 until 1868/10/23
        { name => '明治', period => '明治以降', reading => ['めいじ'], start => [1868,10,23], end => [1912,7,30] }, # 45年 from 1868/10/23 until 1912/7/30
        { name => '大正', period => '登極令下', reading => ['たいしょう'], start => [1912,7,30], end => [1926,12,25] }, # 15年 from 1912/7/30 until 1926/12/25
        { name => '昭和', period => '登極令下', reading => ['しょうわ'], start => [1926,12,25], end => [1989,1,7] }, # 64年 from 1926/12/25 until 1989/1/7
        { name => '平成', period => '元号法下', reading => ['へいせい'], start => [1989,1,8], end => [2019,4,30] }, # 31年 from 1989/1/8 until 2019/4/30
        { name => '令和', period => '元号法下', reading => ['れいわ'], start => [2019,5,1], end => [] }, #  from 2019/5/1 until 
    ];
};

sub new
{
    my $this = shift( @_ );
    return( $this->error( "Incorrect parameters provided. You need to provide an hash of values." ) ) if( @_ % 2 );
    my $p = { @_ };
    $p->{debug} //= 0;
    # kanji_number
    # pattern
    # time_zone
    # traditional
    # zenkaku / hankaku
    if( exists( $p->{hankaku} ) && !exists( $p->{zenkaku} ) )
    {
        $p->{zenkaku} = !$p->{hankaku};
    }
    return( bless( $p => ( ref( $this ) || $this ) ) );
}

sub error
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{error} = $ERROR = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
        warnings::warn( $ERROR, "\n" ) if( warnings::enabled() );
        return;
    }
    return( ref( $self ) ? $self->{error} : $ERROR );
}

sub format_datetime
{
    my $self = shift( @_ );
    my $dt   = shift( @_ );
    require overload;
    return( $self->error( "Value provided (", overload::StrVal( $dt ), ") is not a DateTime object or one inheriting from it." ) ) if( !ref( $dt ) || ( ref( $dt ) && !$dt->isa( 'DateTime' ) ) );
    my $pat  = length( $self->{pattern} ) ? $self->{pattern} : '%c';
    use utf8;
    
    my $japanised_value_for = sub
    {
        my $method_name = shift( @_ );
        my $opts = {};
        $opts = shift( @_ ) if( ref( $_[0] ) eq 'HASH' );
        $opts->{simple_kanji} = 0 if( !exists( $opts->{simple_kanji} ) );
        my $ref = $dt->can( $method_name );
        my $n = $ref->( $dt );
        if( $self->{zenkaku} )
        {
            $n = $self->romaji_to_zenkaku( $n );
        }
        elsif( $self->{kanji_number} )
        {
            if( $opts->{simple_kanji} )
            {
                $n = $self->romaji_to_kanji_simple( $n );
            }
            else
            {
                $n = $self->romaji_to_kanji( $n );
            }
        }
        return( $n );
    };
    my $japanised_strftime = sub
    {
        my $token = shift( @_ );
        my $opts = {};
        $opts = shift( @_ ) if( ref( $_[0] ) eq 'HASH' );
        $opts->{simple_kanji} = 0 if( !exists( $opts->{simple_kanji} ) );
        my $n = $dt->strftime( $token );
        no warnings 'DateTime::Format::JP';
        if( $self->{zenkaku} )
        {
            $n = $self->romaji_to_zenkaku( $n );
        }
        elsif( $self->{kanji_number} )
        {
            if( $opts->{simple_kanji} )
            {
                $n = $self->romaji_to_kanji_simple( $n );
            }
            else
            {
                $n = $self->romaji_to_kanji( $n );
            }
        }
        return( $n );
    };
    
    my $map =
    {
    '%'  => sub{ return( ( $self->{traditional} || $self->{zenkaku} || $self->{kanji_number} ) ? '％' : '%' ); },
    # weekday name in abbreviated form
    'a'  => sub
            {
                my $n = $dt->day_of_week - 1;
                return( $WEEKDAYS->[ $n ] );
            },
    # weekday name in its long form
    'A'  => sub
            {
                my $n = $dt->day_of_week - 1;
                return( $WEEKDAYS->[ $n ] . '曜日' );
            },
    # month name
    'b'  => sub{ return( sprintf( '%d月', $dt->month ) ); },
    # month name using full width (全角) digits
    'B'  => sub{ return( sprintf( '%s月', $self->romaji_to_zenkaku( $dt->month ) ) ); },
    # month name using kanjis for numbers
    'h'  => sub{ return( sprintf( '%s月', $self->romaji_to_kanji( $dt->month ) ) ); },
    # datetime format in the standard most usual form
    # 令和3年7月12日午後2:17:30
    # 令和3年7月12日午後2時17分30秒
    # 令和３年７月１２日午後２時１７分３０秒
    # 令和3年七月十二日午後二時十七分三十秒
    'c'  => sub
            {
                my $era = $self->lookup_era_by_date( $dt ) || return( $self->error( "Unable to find an era for date '$dt'" ) );
                my $def =
                {
                year    => $era->year( $dt ),
                month   => $dt->month,
                day     => $dt->day,
                hour    => $dt->hour_12,
                minute  => $dt->minute,
                second  => $dt->second,
                };
                foreach( keys( %$def ) )
                {
                    if( $self->{zenkaku} )
                    {
                        $def->{ $_ } = $self->romaji_to_zenkaku( $def->{ $_ } );
                    }
                    elsif( $self->{kanji_number} )
                    {
                        $def->{ $_ } = $self->romaji_to_kanji( $def->{ $_ } );
                    }
                }
                if( $self->{traditional} || $self->{kanji_number} )
                {
                    $def->{suff_hour}   = '時';
                    $def->{suff_minute} = '分';
                    $def->{suff_second} = '秒';
                    return( sprintf( '%s%s年%s月%s日%s%s%s%s%s%s%s', $era->name, @$def{qw( year month day )}, ( $dt->hour > 12 ? '午後' : '午前' ), @$def{qw( hour suff_hour minute suff_minute second suff_second )} ) );
                }
                else
                {
                    $def->{sep} = $self->{zenkaku} ? '：' : ':';
                    return( sprintf( '%s%s年%s月%s日%s%s%s%s%s%s', $era->name, @$def{qw( year month day )}, ( $dt->hour > 12 ? '午後' : '午前' ), @$def{qw( hour sep minute sep second )} ) );
                }
            },
    # century number (0-99)
    'C'  => sub{ return( $dt->strftime( '%C' ) ); },
    # day of month
    'd'  => sub{ return( $japanised_value_for->( 'day' ) ); },
    # Japanese style date including with the leading era name
    'D'  => sub
            {
                my $era = $self->lookup_era_by_date( $dt ) || return( $self->error( "Unable to find an era for date '$dt'" ) );
                my $def =
                {
                year    => $era->year( $dt ),
                month   => $dt->month,
                day     => $dt->day,
                };
                foreach( keys( %$def ) )
                {
                    if( $self->{zenkaku} )
                    {
                        $def->{ $_ } = $self->romaji_to_zenkaku( $def->{ $_ } );
                    }
                    elsif( $self->{kanji_number} )
                    {
                        $def->{ $_ } = $self->romaji_to_kanji( $def->{ $_ } );
                    }
                }
                return( sprintf( '%s%s年%s月%s日', $era->name, @$def{qw( year month day )} ) );
            },
    # Japanese era name
    'E'  => sub
            {
                my $e = $self->lookup_era_by_date( $dt ) || return;
                return( $e->name );
            },
    # Equivalent to "%Y年%m月%d日"
    'F'  => sub
            {
                my $def =
                {
                year    => $dt->year,
                month   => $dt->month,
                day     => $dt->day,
                };
                foreach( qw( month day ) )
                {
                    if( $self->{zenkaku} )
                    {
                        $def->{ $_ } = $self->romaji_to_zenkaku( $def->{ $_ } );
                    }
                    elsif( $self->{kanji_number} )
                    {
                        $def->{ $_ } = $self->romaji_to_kanji( $def->{ $_ } );
                    }
                }
                
                if( $self->{zenkaku} )
                {
                    $def->{year} = $self->romaji_to_zenkaku( $def->{year} );
                }
                elsif( $self->{kanji_number} )
                {
                    $def->{year} = $self->romaji_to_kanji_simple( $def->{year} );
                }
                
                return( sprintf( '%s年%s月%s日', @$def{qw( year month day )} ) );
            },
    # year without century
    'g'  => sub{ return( $dt->strftime( '%g' ) ); },
    # week number 4-digit year
    'G'  => sub{ return( $dt->strftime( '%G' ) ); },,
    # hour
    'H'  => sub{ return( $japanised_value_for->( 'hour' ) . ( ( $self->{traditional} || $self->{kanji_number} ) ? '時' : '' ) ); },
    # hour with clock of 12
    'I'  => sub{ return( $japanised_value_for->( 'hour_12' ) ); },
    # day number in the year
    'j'  => sub{ return( $dt->strftime( '%j' ) ); },
    # month number
    'm'  => sub{ return( $japanised_value_for->( 'month' ) ); },
    # minute
    'M'  => sub{ return( $japanised_value_for->( 'minute' ) . ( ( $self->{traditional} || $self->{kanji_number} ) ? '分' : '' ) ); },
    # space
    'n'  => sub{ return( $dt->strftime( '%n' ) ); },
    # AM/PM
    'p'  => sub{ return( $dt->hour > 12 ? '午後' : '午前' ); },
    # Equivalent to "%p%I:%M:%S"
    'r'  => sub{ return( sprintf( '%s%s%s%s%s%s', ( $dt->hour > 12 ? '午後' : '午前' ), $japanised_value_for->( 'hour_12' ), ( $self->{zenkaku} ? '：' : ':' ), $japanised_value_for->( 'minute' ), ( $self->{zenkaku} ? '：' : ':' ), $japanised_value_for->( 'second' ) ) ); },
    # Equivalent to "%H:%M"
    'R'  => sub{ return( sprintf( '%s%s%s', $japanised_value_for->( 'hour' ), ( $self->{zenkaku} ? '：' : ':' ), $japanised_value_for->( 'minute' ) ) ); },
    # seconds since the Epoch
    's'  => sub{ return( $self->{zenkaku} ? $self->romaji_to_zenkaku( $dt->strftime( '%s' ) ) : $dt->strftime( '%s' ) ); },
    # seconds
    'S'  => sub{ return( $japanised_value_for->( 'second' ) . ( ( $self->{traditional} || $self->{kanji_number} ) ? '秒' : '' ) ); },
    # space
    't'  => sub{ return( $dt->strftime( '%t' ) ); },
    # Equivalent to "%H:%M:%S"
    'T'  => sub{ return( sprintf( '%s%s%s%s%s', $japanised_value_for->( 'hour' ), ( $self->{zenkaku} ? '：' : ':' ), $japanised_value_for->( 'minute' ), ( $self->{zenkaku} ? '：' : ':' ), $japanised_value_for->( 'second' ) ) ); },
    # week number with Sunday first
    'U'  => sub{ return( $japanised_strftime->( '%U' ) ); },
    # weekday number 1-7
    'u'  => sub{ return( $japanised_value_for->( 'day_of_week' ) ); },
    # weekday number 0-7 with Sunday first
    'w'  => sub{ return( $japanised_strftime->( '%w' ) ); },
    # week number with Monday first
    'W'  => sub{ return( $japanised_strftime->( '%W' ) ); },
    # date format in the standard most usual form
    # 令和3年7月12日
    # 令和３年７月１２日
    # 令和3年七月十二日
    'x'  => sub
            {
                my $era = $self->lookup_era_by_date( $dt ) || return( $self->error( "Unable to find an era for date '$dt'" ) );
                my $def =
                {
                year  => $era->year( $dt ),
                month => $dt->month,
                day   => $dt->day,
                };
                foreach( keys( %$def ) )
                {
                    if( $self->{zenkaku} )
                    {
                        $def->{ $_ } = $self->romaji_to_zenkaku( $def->{ $_ } );
                    }
                    elsif( $self->{kanji_number} )
                    {
                        $def->{ $_ } = $self->romaji_to_kanji( $def->{ $_ } );
                    }
                }
                return( sprintf( '%s%s年%s月%s日', $era->name, @$def{qw( year month day )} ) );
            },
    # time format in the standard most usual form
    # 午後2:17:30
    # 午後2時17分30秒
    # 午後二時十七分三十秒
    'X'  => sub
            {
                my $def =
                {
                hour   => $dt->hour_12,
                minute => $dt->minute,
                second => $dt->second,
                };
                $def->{ampm} = $dt->hour > 12 ? '午後' : '午前';
                $def->{sep1} = $def->{sep2} = ':';
                if( $self->{traditional} || $self->{kanji_number} )
                {
                    $def->{suff_hour}   = '時';
                    $def->{suff_minute} = '分';
                    $def->{suff_second} = '秒';
                    delete( @$def{qw( sep1 sep2 )} );
                }
                elsif( $self->{zenkaku} )
                {
                    $def->{sep1} = $def->{sep2} = '：';
                }
                
                foreach( qw( hour minute second ) )
                {
                    if( $self->{zenkaku} )
                    {
                        $def->{ $_ } = $self->romaji_to_zenkaku( $def->{ $_ } );
                    }
                    elsif( $self->{kanji_number} )
                    {
                        $def->{ $_ } = $self->romaji_to_kanji( $def->{ $_ } );
                    }
                }
                
                if( $self->{traditional} || $self->{kanji_number} )
                {
                    return( sprintf( '%s%s%s%s%s%s%s', @$def{qw( ampm hour suff_hour minute suff_minute second suff_second )} ) );
                }
                else
                {
                    return( sprintf( '%s%s%s%s%s%s', @$def{qw( ampm hour sep1 minute sep2 second )} ) );
                }
            },
    # year of the era, relative to the start of the era
    'y'  => sub
            {
                my $era = $self->lookup_era_by_date( $dt ) || return( $self->error( "Unable to find an era for date '$dt'" ) );
                my $y = $era->year( $dt );
                if( $self->{zenkaku} )
                {
                    $y = $self->romaji_to_zenkaku( $y );
                }
                elsif( $self->{kanji_number} )
                {
                    $y = $self->romaji_to_kanji( $y );
                }
                return( $y );
            },
    # 4-digit year
    'Y'  => sub{ return( $japanised_value_for->( 'year', { simple_kanji => 1 }) ); },
    # standard time zone specification, such as +0900
    'z'  => sub
            {
                my $rv = $japanised_strftime->( '%z', { simple_kanji => 1 });
                if( $self->{zenkaku} || $self->{traditional} || $self->{kanji_number} )
                {
                    if( substr( $rv, 0, 1 ) eq '+' )
                    {
                        substr( $rv, 0, 1, '＋' );
                    }
                    elsif( substr( $rv, 0, 1 ) eq '-' )
                    {
                        substr( $rv, 0, 1, 'ー' );
                    }
                }
                return( $rv );
            },
    # timezone name
    'Z'  => sub{ return( $dt->strftime( '%Z' ) ); },
    };
    # Aliases
    $map->{e} = $map->{d};
    $map->{P} = $map->{p};
    $pat =~ s
    {
        \%([\%aAbBhcCdeDEFgGHIjmMnNpPrRRsStTUuwWxXyYzZ])
    }
    {
        my $token = $1;
        die( "Missing definition for '$token'\n" ) if( !exists( $map->{ $token } ) );
        $map->{ $token }->();
    }gexs;

    $pat =~ s
    {
        \%\{(\w+)\}
    }
    {
        my $meth = $1;
        my $code = $dt->can( $meth );
        if( $code )
        {
            $code->( $dt );
        }
        else
        {
            warnings::warn( "Unsupported DateTime method \"${meth}\" found in pattern.\n" ) if( warnings::enabled() );
            '%{' . $meth . '}';
        }
    }gexs;
    
    if( index( $pat, '%' ) != -1 )
    {
        $pat = $dt->strftime( $pat );
    }
    return( $pat );
}

sub hankaku { return( shift->_set_get_zenkaku( 'hankaku', @_ ) ); }

sub kanji_number { return( shift->_set_get( 'kanji_number', @_ ) ); }

sub kanji_to_romaji
{
    my $self = shift( @_ );
    my $num  = shift( @_ );
    return( $self->error( "No value provided to transcode from kanji number to roman numerals." ) ) if( !defined( $num ) || !length( $num ) );
    use utf8;
    my $rv = 0;
    if( $num =~ s/^[[:blank:]\h]*([〇一二三四五六七八九])千// )
    {
        my $n = $self->_get_pos_in_array( $KANJI_NUMBERS, $1 );
        $rv = $n * 1000;
    }
    if( length( $num ) && $num =~ s/^([〇一二三四五六七八九])百// )
    {
        my $n = $self->_get_pos_in_array( $KANJI_NUMBERS, $1 );
        $rv += ( $n * 100 );
    }
    if( length( $num ) && $num =~ s/^([〇一二三四五六七八九])十// )
    {
        my $n = $self->_get_pos_in_array( $KANJI_NUMBERS, $1 );
        $rv += ( $n * 10 );
    }
    if( length( $num ) )
    {
        my $n = $self->_get_pos_in_array( $KANJI_NUMBERS, $num );
        $rv += $n;
    }
    return( $rv );
}

sub lookup_era
{
    my $self = shift( @_ );
    my $name = shift( @_ ) ||
        return( $self->error( "No era name was provided to lookup." ) );
    foreach my $ref ( @$DICT )
    {
        if( $ref->{name} eq $name )
        {
            return( DateTime::Format::JP::Era->new( $ref ) );
        }
    }
    # Nothing found
    return;
}

sub lookup_era_by_date
{
    my $self = shift( @_ );
    my $dt   = shift( @_ );
    require overload;
    return( $self->error( "Value provided (", overload::StrVal( $dt ), ") is not a DateTime object or one inheriting from it." ) ) if( !ref( $dt ) || ( ref( $dt ) && !$dt->isa( 'DateTime' ) ) );
    my( $y, $m, $d ) = unpack( 'A4A2A2', $dt->ymd( '' ) );
    my $era;
    foreach my $def ( @$DICT )
    {
        # No need to bother if the current entry has an end and it is lower than our current year
        next if( scalar( @{$def->{end}} ) && $y > $def->{end}->[0] );
        if( scalar( @{$def->{start}} ) && 
            scalar( @{$def->{end}} ) && 
            $y >= $def->{start}->[0] && 
            $y <= $def->{end}->[0] && 
            $m >= $def->{start}->[1] &&
            $m <= $def->{end}->[1] &&
            $d >= $def->{start}->[2] &&
            $d < $def->{end}->[2] )
        {
            $era = DateTime::Format::JP::Era->new( $def );
            last;
        }
        # Obviously the current era, i.e. it has no end date
        elsif( scalar( @{$def->{start}} ) &&
               !scalar( @{$def->{end}} ) &&
               $y >= $def->{start}->[0] && 
               $m >= $def->{start}->[1] &&
               $d >= $def->{start}->[2] )
        {
            $era = DateTime::Format::JP::Era->new( $def );
            last;
        }
    }
    return( $era );
}

sub make_datetime
{
    my $self = shift( @_ );
    my $opts = shift( @_ );
    use utf8;
    return( $self->error( "Parameter provided is not an hash reference." ) ) if( ref( $opts ) ne 'HASH' );
    for( qw( year month day ) )
    {
        return( $self->error( "Missing the $_ parameter." ) ) if( !length( $opts->{ $_ } ) );
    }
    if( length( $opts->{ampm} ) && $opts->{ampm} eq '午後' )
    {
        $opts->{hour} += 12;
    }
    
    try
    {
        my $dt;
        if( $opts->{era} && ref( $opts->{era} ) )
        {
            my $era = $opts->{era};
            $dt = $era->start_datetime;
            $dt->add( years => ( $opts->{year} - 1 ) ) if( $opts->{year} > 1 );
            $dt->set_month( $opts->{month} );
            $dt->set_day( $opts->{day} );
        }
        else
        {
            my $p =
            {
            year => $opts->{year},
            month => $opts->{month},
            day => $opts->{day},
            };
            if( length( $opts->{time_zone} ) )
            {
                $p->{time_zone} = $opts->{time_zone};
            }
            elsif( length( $self->{time_zone} ) )
            {
                $p->{time_zone} = $self->{time_zone};
            }
        
            $dt = DateTime->new( %$p );
        }
        $dt->set_hour( $opts->{hour} ) if( $opts->{hour} );
        $dt->set_minute( $opts->{minute} ) if( $opts->{minute} );
        $dt->set_second( $opts->{second} ) if( $opts->{second} );
        return( $dt );
    }
    catch( $e )
    {
        return( $e );
    }
}

sub message
{
    my $self = shift( @_ );
    my $level = shift( @_ );
    return(1) if( $self->{debug} < int( $level // 0 ) );
    my $msg  = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
    chomp( $msg );
    print( STDERR "# ", join( "\n# ", split( /\n/, $msg ) ), "\n" );
    return(1);
}

sub parse_datetime
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    use utf8;
    if( $str =~ /$DATETIME_PATTERN_1_RE/ )
    {
        my $re = { %+ };
        if( $re->{era} )
        {
            my $era = $self->lookup_era( $re->{era} ) || 
                return( $self->error( "No era \"$re->{era}\" could be found." ) );
            $re->{era} = $era;
        }
        else
        {
            $re->{year} = delete( $re->{gregorian_year} );
        }
        for( qw( year month day ) )
        {
            next if( $re->{ $_ } =~ /^[0-9]+$/ );
            my $rv = $self->zenkaku_to_romaji( $re->{ $_ } );
            # Pass on the error, if any
            return( $self->error( "Unable to transcode full width number \"", $re->{ $_ }, "\" in \"$_\" to half width." ) ) if( !defined( $rv ) );
            $re->{ $_ } = $rv;
        }
        for( qw( hour minute second ) )
        {
            next if( !length( $re->{ $_ } ) || $re->{ $_ } =~ /^[0-9]+$/ );
            my $rv = $self->zenkaku_to_romaji( $re->{ $_ } );
            # Pass on the error, if any
            return( $self->error( "Unable to transcode full width number \"", $re->{ $_ }, "\" in \"$_\" to half width." ) ) if( !defined( $rv ) );
            $re->{ $_ } = $rv;
        }
        $self->_dump( $re );
        return( $self->make_datetime( $re ) );
    }
    # With full width roman number
    elsif( $str =~ /$DATETIME_PATTERN_2_RE/ )
    {
        my $re = { %+ };
        if( $re->{era} )
        {
            my $era = $self->lookup_era( $re->{era} ) || 
                return( $self->error( "No era \"$re->{era}\" could be found." ) );
            $re->{era} = $era;
        }
        else
        {
            $re->{year} = delete( $re->{gregorian_year} );
        }
        $self->_dump( $re );
        return( $self->make_datetime( $re ) );
    }
    # With numbers in Kanji
    elsif( $str =~ /$DATETIME_PATTERN_3_RE/ )
    {
        my $re = { %+ };
        if( $re->{era} )
        {
            my $era = $self->lookup_era( $re->{era} ) || 
                return( $self->error( "No era \"$re->{era}\" could be found." ) );
            $re->{era} = $era;
        }
        else
        {
            $re->{year} = delete( $re->{gregorian_year} );
        }
        for( qw( year month day ) )
        {
            my $rv = $self->kanji_to_romaji( $re->{ $_ } );
            # Pass on the error, if any
            return( $self->error( "Unable to transcode full width number \"", $re->{ $_ }, "\" in \"$_\" to half width." ) ) if( !defined( $rv ) );
            $re->{ $_ } = $rv;
        }
        for( qw( hour minute second ) )
        {
            next if( !length( $re->{ $_ } ) );
            my $rv = $self->kanji_to_romaji( $re->{ $_ } );
            # Pass on the error, if any
            return( $self->error( "Unable to transcode full width number \"", $re->{ $_ }, "\" in \"$_\" to half width." ) ) if( !defined( $rv ) );
            $re->{ $_ } = $rv;
        }
        return( $self->make_datetime( $re ) );
    }
    else
    {
        return( $self->error( "Unknown datetime pattern \"$str\"" ) );
    }
}

sub romaji_to_kanji
{
    my $self = shift( @_ );
    my $num  = shift( @_ );
    return( $num ) if( !defined( $num ) || !length( $num ) );
    use utf8;
    my $buff = [];
    $num =~ s/[^0-9]+//g;
    if( $num =~ s/^(\d)(\d{3})$/$2/ )
    {
        push( @$buff, ( $1 > 1 ? $KANJI_NUMBERS->[ $1 ] : () ), '千' );
    }
    $num =~ s/^0+([1-9][0-9]*)$/$1/;
    
    unless( !length( $num ) || $num =~ /^0+$/ )
    {
        if( $num =~ s/^(\d)(\d{2})$/$2/ )
        {
            push( @$buff, ( $1 > 1 ? $KANJI_NUMBERS->[ $1 ] : () ), '百' );
        }
        $num =~ s/^0+([1-9][0-9]*)$/$1/;
        
        unless( !length( $num ) || $num =~ /^0+$/ )
        {
            if( $num =~ s/^(\d)(\d)$/$2/ )
            {
                push( @$buff, ( $1 > 1 ? $KANJI_NUMBERS->[ $1 ] : () ), '十' );
            }
            $num = '' if( $num == 0 );

            unless( !length( $num ) || $num =~ /^0+$/ )
            {
                push( @$buff, $KANJI_NUMBERS->[ $num ] );
            }
        }
    }
    return( join( '', @$buff ) );
}

sub romaji_to_kanji_simple
{
    my $self = shift( @_ );
    my $num  = shift( @_ );
    return( $num ) if( !defined( $num ) || !length( $num ) );
    my $buff = [];
    foreach( split( //, $num ) )
    {
        if( $_ !~ /^[0-9]$/ )
        {
            push( @$buff, $_ );
            next;
        }
        push( @$buff, $KANJI_NUMBERS->[ $_ ] );
    }
    return( join( '', @$buff ) );
}

sub romaji_to_zenkaku
{
    my $self = shift( @_ );
    my $num  = shift( @_ );
    use utf8;
    # Already done
    return( $num ) if( $num =~ /^[０１２３４５６７８９]+$/ );
    my $buff = [];
    for( split( //, $num ) )
    {
        if( /^[０１２３４５６７８９]$/ )
        {
            push( @$buff, $_ );
        }
        elsif( /^[0-9]$/ )
        {
            push( @$buff, $ZENKAKU_NUMBERS->[ $_ ] );
        }
        else
        {
            warnings::warn( "Unknown character \"$_\" in number \"$num\" to be cnverted into full width.\n" ) if( warnings::enabled() );
            push( @$buff, $_ );
        }
    }
    return( join( '', @$buff ) );
}

sub time_zone { return( shift->_set_get( 'time_zone', @_ ) ); }

sub traditional { return( shift->_set_get( 'traditional', @_ ) ); }

sub zenkaku { return( shift->_set_get_zenkaku( 'zenkaku', @_ ) ); }

sub zenkaku_to_romaji { return( shift->_get_pos_in_array( $ZENKAKU_NUMBERS, @_ ) ); }

sub _dump
{
    my $self = shift( @_ );
    my $ref  = shift( @_ );
    return(1) if( !$self->{debug} );
    foreach my $k ( sort( keys( %$ref ) ) )
    {
        printf( STDERR "%-12s: %s\n", $k, $ref->{ $k } );
    }
    print( STDERR "-" x 20, "\n" );
    return(1);
}

sub _get_pos_in_array
{
    my $self  = shift( @_ );
    my $array = shift( @_ );
    my $num   = shift( @_ );
    return( $self->error( "I was expecting an array reference, but I got \"$array\"." ) ) if( ref( $array ) ne 'ARRAY' );
    return( $self->error( "Array provided is empty!" ) ) if( !scalar( @$array ) );
    return( $self->error( "No value provided to transcode!" ) ) if( !defined( $num ) || !length( $num ) );
    my $buff  = [];
    my( $index1 ) = grep{ $num eq $array->[$_] } 0..$#$array;
    return( $index1 ) if( length( $index1 ) );
    
    for my $c ( split( //, $num ) )
    {
        if( $c =~ /^[0-9]$/ )
        {
            push( @$buff, $c );
            next;
        }
        my( $index ) = grep{ $c eq $array->[$_] } 0..$#$array;
        return( $self->error( "Failed to find the corresponding entry for \"$c\"." ) ) if( !length( $index ) );
        push( @$buff, $index );
    }
    return( join( '', @$buff ) );
}

sub _set_get
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    if( @_ )
    {
        $self->{ $field } = shift( @_ );
    }
    return( $self->{ $field } );
}

sub _set_get_zenkaku
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    if( @_ )
    {
        my $v = shift( @_ );
        $self->{ $field } = $v;
        if( $field eq 'zenkaku' )
        {
            $self->{hankaku} = !$v;
        }
        elsif( $field eq 'hankaku' )
        {
            $self->{zenkaku} = !$v;
        }
    }
    return( $self->{ $field } );
}

# NOTE: DateTime::Format::JP::Era class
{
    package
        DateTime::Format::JP::Era;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Exporter );
        use vars qw( $ERROR );
        use DateTime;
        use DateTime::TimeZone;
        use Nice::Try;
        use constant HAS_LOCAL_TZ => ( eval( qq{DateTime::TimeZone->new( name => 'local' );} ) ? 1 : 0 );
    };

    use strict;
    use warnings;
    
    # my $era = DateTime::Format::JP::Era->new( $era_dictionary_hash_ref );
    sub new { return( bless( $_[1] => ( ref( $_[0] ) || $_[0] ) ) ); }
    
    sub error
    {
        my $self = shift( @_ );
        if( @_ )
        {
            $self->{error} = $ERROR = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
            warnings::warn( $ERROR, "\n" ) if( warnings::enabled( 'DateTime::Format::JP' ) );
            return;
        }
        return( ref( $self ) ? $self->{error} : $ERROR );
    }

    sub end { return( [@{shift->{end}}] ); }

    sub end_datetime { return( shift->_get_datetime( 'end' ) ); }
    
    sub name { return( shift->{name} ); }
    
    sub period { return( shift->{period} ); }
    
    sub reading { return( [@{shift->{reading}}] ); }

    sub start { return( [@{shift->{start}}] ); }
    
    sub start_datetime { return( shift->_get_datetime( 'start' ) ); }
    
    sub year
    {
        my( $self, $dt ) = @_;
        # First year is Year 1 of an era no matter when it starts in that year
        return( ( $dt->year + 1 ) - $self->{start}->[0] );
    }
    
    sub _get_datetime
    {
        my $self = shift( @_ );
        my $field = shift( @_ );
        my $ref = $self->{ $field };
        try
        {
            if( ref( $ref ) eq 'ARRAY' && scalar( @$ref ) == 3 )
            {
                my $opts = {};
                @$opts{qw( year month day )} = @$ref;
                @$opts{qw( hour minute second )} = (0,0,0);
                $opts->{time_zone} = ( HAS_LOCAL_TZ ? 'local' : 'UTC' );
                return( DateTime->new( %$opts ) );
            }
            else
            {
                return( DateTime->now( time_zone => ( HAS_LOCAL_TZ ? 'local' : 'UTC' ) ) );
            }
        }
        catch( $e )
        {
            return( $self->error( $e ) );
        }
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

DateTime::Format::JP - Japanese DateTime Parser and Formatter

=head1 SYNOPSIS

    use DateTime::Format::JP;
    my $fmt = DateTime::Format::JP->new(
        hankaku      => 1,
        pattern      => '%c', # default
        traditional  => 0,
        kanji_number => 0,
        zenkaku      => 0,
        time_zone    => 'local',
    );
    my $dt = DateTime->now;
    $dt->set_formatter( $fmt );
    # set the encoding in and out to utf8
    use open ':std' => ':utf8';
    print "$dt\n"; # will print something like 令和3年7月12日午後2:30:20

    my $dt  = $fmt->parse_datetime( "令和３年７月１２日午後２時３０分" );
    
    my $str = $fmt->format_datetime( $dt );
    print "$str\n";

=head1 VERSION

    v0.1.4

=head1 DESCRIPTION

This module is used to parse and format Japanese date and time. It is lightweight and yet versatile.

It implements 2 main methods: L</parse_datetime> and L</format_datetime> both expect and return decoded utf8 string.

You can use L<Encode> to decode and encode from perl internal utf8 representation to real utf8 and vice versa.

=head1 METHODS

=head2 new

The constructor accepts the following parameters:

=over 4

=item I<hankaku> boolean

If true, the digits used will be "half-size" (半角), or roman numbers like 1, 2, 3, etc.

The opposite is I<zenkaku> (全角) or full-width. This will enable the use of double-byte Japanese numbers that still look like roman numbers, such as: １, ２, ３, etc.

Defaults to true.

=item I<pattern> string

The pattern to use to format the date and time. See below the available L</"PATTERN TOKENS"> and their meanings.

Defaults to C<%c>

=item I<traditional> boolean

If true, then it will use a more traditional date/time representation. The effect of this parameter on the formatting is documented in L</"PATTERN TOKENS">

=item I<kanji_number> boolean

If true, this will have L</format_datetime> use numbers in kanji, such as: 一, 二, 三, 四, etc.

=item I<zenkaku> boolean

If true, this will use full-width, ie double-byte Japanese numbers that still look like roman numbers, such as: １, ２, ３, etc.

=item I<time_zone> string

The time zone to use when creating a L<DateTime> object. Defaults to C<local> if L<DateTime::TimeZone> supports it, otherwise it will fallback on C<UTC>

=back

=head2 error

Returns the latest error set, if any.

All method in this module return C<undef> upon error and set an error that can be retrieved with this method.

=head2 format_datetime

Takes a L<DateTime> object and returns a formatted date and time based on the pattern specified, which defaults to C<%c>. 

You can call this method directly, or you can set this formatter object in L<DateTime/set_formatter> so that ie will be used for stringification of the L<DateTime> object.

See below L</"PATTERN TOKENS"> for the available tokens and their meanings.

=head2 hankaku

Sets or gets the boolean value for I<hankaku>.

=head2 kanji_number

Sets or gets the boolean value for I<kanji_number>.

=head2 parse_datetime

Takes a string representing a Japanese date, parse it and return a new L<DateTime>. If an error occurred, it will return C<undef> and you can get the error using L</error>

=head2 time_zone

Sets or gets the string representing the time zone to use when creating L<DateTime> object. This is used by L</parse_datetime>

=head2 traditional

Sets or gets the boolean value for I<traditional>.

=head2 zenkaku

Sets or gets the boolean value for I<zenkaku>.

=head1 SUPPORT METHODS

=head2 kanji_to_romaji

Takes a number in kanji and returns its equivalent value in roman (regular) numbers.

=head2 lookup_era

Takes an Japanese era in kanji and returns an C<DateTime::Format::JP::Era> object

=head2 lookup_era_by_date

Takes a L<DateTime> object and returns a C<DateTime::Format::JP::Era> object

=head2 make_datetime

Returns a L<DateTime> based on parameters provided.

=head2 romaji_to_kanji

Takes a number and returns its equivalent representation in Japanese kanji. Thus, for example, C<1234> would be returned as C<千二百三十四>

Please note that, since this is intended to be used only for dates, it does not format number over 9 thousand. If you think there is such need, please contact the author.

=head2 romaji_to_kanji_simple

Replaces numbers with their Japanese kanji equivalent. It does not use numerals.

=head2 romaji_to_zenkaku

Takes a number and returns its equivalent representation in double-byte Japanese numbers. Thus, for example, C<1234> would be returned as C<１２３４>

=head2 zenkaku_to_romaji

Takes a string representing a number in full width (全角), i.e. double-byte and returns a regular equivalent number. Thus, for example, C<１２３４> would be returned as C<1234>

=head1 PATTERN TOKENS

Here are below the available tokens for formatting and the value they represent.

In all respect, they are closely aligned with L<DateTime/strftime> (see L<DateTime/"strftime Patterns">), except that the formatter object parameters provided upon instantiation alter the values used.

=over 4

=item * %%

The % character.

=item * %a

The weekday name in abbreviated form such as: 月, 火, 水, 木, 金, 土, 日

=item * %A

The weekday name in its long form such as: 月曜日, 火曜日, 水曜日, 木曜日, 金曜日, 土曜日, 日曜日

=item * %b

The month name, such as 1月, 2月, etc... 12月 using regular digits.

=item * %B

The month name using full width (全角) digits, such as １月, ２月, etc... １２月

=item * %h

The month name using kanjis for numbers, such as 一月, 二月, etc... 十二月

=item * %c

The datetime format in the Japanese standard most usual form. For example for C<12th July 2021 14:17:30> this would be:

    令和3年7月12日午後2:17:30

However, if I<traditional> is true, then it would rather be:

    令和3年7月12日午後2時17分30秒

And if I<zenkaku> is true, it will use double-byte numbers instead:

    令和３年７月１２日午後２時１７分３０秒

And if I<kanji_number> is true, it will then be:

    令和三年七月十二日午後二時十七分三十秒

=item * %C

The century number (year/100) as a 2-digit integer. This is the same as L<DateTime/strftime>

=item * %d or %e

The day of month (1-31).

However, if I<zenkaku> is true, then it would rather be with full width (全角) numbers: １-３１

And if I<kanji_number> is true, it will then be with numbers in kanji: 一, 二, etc.. 十, 十一, etc..

=item * %D

Equivalent to C<%E%y年%m月%d日>

This is the Japanese style date including with the leading era name.

If I<zenkaku> is true, "full-width" (double byte) digits will be used and if I<kanji_number> is true, numbers in kanji will be used instead.

See %F for an equivalent date using the Gregorian years rather than the Japanese era.

=item * %E

This extension is the Japanese era, such as C<令和> (i.e. "reiwa": the current era)

=item * %F

Equivalent to C<%Y年%m月%d日>

If I<zenkaku> is true, "full-width" (double byte) digits will be used and if I<kanji_number> is true, numbers in kanji will be used instead.

For the year only the conversion from regular digits to Japanese kanjis will be done simply by interpolating the digits and not using numerals. For example C<2021> would become C<二〇二一> and not C<二千二十一>

=item * %g

The year corresponding to the ISO week number, but without the century (0-99). This uses regular digits and is the same as L<DateTime/strftime>

=item * %G

The ISO 8601 year with century as a decimal number. The 4-digit year corresponding to the ISO week number. This has the same format and value as %Y, except that if the ISO week number belongs to the previous or next year, that year is used instead. Also this returns regular digits.

This uses regular digits and is the same as L<DateTime/strftime>

=item * %H

The hour: 0-23

If I<traditional> is enabled, this would rather be C<0-23時>

However, if I<zenkaku> is true, then it would rather use full width (全角) numbers: C<０-２３時>

And if I<kanji_number> is true, it will then be something like C<十時>

=item * %I

The hour on a 12-hour clock (1-12).

If I<zenkaku> is true, it will use full width numbers and if I<kanji_number> is true, it will use numbers in kanji instead.

=item * %j

The day number in the year (1-366). This uses regular digits and is the same as L<DateTime/strftime>

=item * %m

The month number (1-12).

If I<zenkaku> is true, it will use full width numbers and if I<kanji_number> is true, it will use numbers in kanji instead.

=item * %M

The minute: 0-59

If I<traditional> is enabled, this would rather be C<0-59分>

However, if I<zenkaku> is true, then it would rather use full width (全角) numbers: C<０-５９分>

And if I<kanji_number> is true, it will then be something like C<十分>

=item * %n

Arbitrary whitespace. Same as in L<DateTime/strftime>

=item * %N

Nanoseconds. For other sub-second values use C<%[number]N>.

This is a pass-through directly to L<DateTime/strftime>

=item * %p or %P

Either produces the same result.

Either AM (午前) or PM (午後) according to the given time value. Noon is treated as pm "午後" and midnight as am "午前".

=item * %r

Equivalent to C<%p%I:%M:%S>

Note that if I<zenkaku> is true, the semi-colon used will be double-byte: C<：>

Also if you use this, do not enable I<kanji_number>, because the result would be weird, something like:

    午後二：十四：三十 # 2:14:30 in this example

=item * %R

Equivalent to C<%H:%M>

Note that if I<zenkaku> is true, the semi-colon used will be double-byte: C<：>

Juste like for C<%r>, avoid enabling I<kanji_number> if you use this token.

=item * %s

Number of seconds since the Epoch.

If I<zenkaku> is enabled, this will return the value as double-byte number.

=item * %S

The second: C<0-60>

If I<traditional> is enabled, this would rather be C<0-60秒>

However, if I<zenkaku> is true, then it would rather use full width (全角) numbers: C<０-６０秒>

And if I<kanji_number> is true, it will then be something like C<六十秒>

(60 may occur for leap seconds. See L<DateTime::LeapSecond>).

=item * %t

Arbitrary whitespace. Same as in L<DateTime/strftime>

=item * %T

Equivalent to C<%H:%M:%S>

However, if I<zenkaku> option is enabled, the numbers will be double-byte roman numbers and the separator will also be double-byte. For example:

    １４：２０：３０

=item * %U

The week number with Sunday (日曜日) the first day of the week (0-53). The first　Sunday of January is the first day of week 1.

If I<zenkaku> is enabled, it will return a double-byte number instead.

=item * %u

The weekday number (1-7) with Monday (月曜日) = 1, 火曜日 = 2, 水曜日 = 3, 木曜日 = 4, 金曜日 = 5, 土曜日 = 6, 日曜日 = 7

If I<zenkaku> is enabled, it will return a double-byte number instead.

This is the C<DateTime> standard.

=item * %w

The weekday number (0-6) with Sunday = 0.

If I<zenkaku> is enabled, it will return a double-byte number instead.

=item * %W

The week number with Monday (月曜日) the first day of the week (0-53). The first　Monday of January is the first day of week 1.

If I<zenkaku> is enabled, it will return a double-byte number instead.

=item * %x

The date format in the standard most usual form. For example for 12th July 2021 this would be:

    令和3年7月12日

However, if I<zenkaku> is true, then it would rather be:

    令和３年７月１２日

And if I<kanji_number> is true, it will then be:

    令和三年七月十二日

=item * %X

The time format in the standard most usual form. For example for C<14:17:30> this would be:

    午後2:17:30

And if I<zenkaku> is enabled, it would rather use a double-byte numbers and separator:

    午後２：１７：３０

However, if I<traditional> is true, then it would rather be:

    午後2時17分30秒

And if I<kanji_number> is true, it will then be:

    午後二時十七分三十秒

=item * %y

The year of the era. For example C<2021-07-12> would be C<令和3年7月12日> and thus the year value would be C<3>

If I<zenkaku> is true, it will use full width numbers and if I<kanji_number> is true, it will use numbers in kanji instead.

=item * %Y

A 4-digit year, including century (for example, 1991).

If I<zenkaku> is true, "full-width" (double byte) digits will be used and if I<kanji_number> is true, numbers in kanji will be used instead.

Same as in C<%F>, the conversion from regular digits to Japanese kanjis will be done simply by interpolating the digits and not using numerals. For example C<2021> would become C<二〇二一> and not C<二千二十一>

=item * %z

An RFC-822/ISO 8601 standard time zone specification. (For example
+1100)

If I<zenkaku> is true, "full-width" (double byte) digits and C<+/-> signs will be used and if I<kanji_number> is true, numbers in kanji will be used instead. However, no numeral will be used. Thus a time zone offset such as C<+0900> would be returned as C<＋〇九〇〇>

=item * %Z

The timezone name. (For example EST -- which is ambiguous). This is the same as L<DateTime/strftime>

=back

=head1 HISTORICAL NOTE

Japanese eras, also known as 元号 (gengo) or 年号 (nengo) form one of the two parts of a Japanese year in any given date.

It was instituted by and under first Emperor Kōtoku in 645 AD. So be warned that requiring an era-based Japanese date before will not yield good results.

Era name were adopted for various reasons such as a to commemorate an auspicious or ward off a malign event, and it is only recently that era name changes are tied to a new Emperor.

More on this L<here|https://en.wikipedia.org/wiki/Japanese_era_name>

From 1334 until 1392, there were 2 competing regimes in Japan; the North and South. This period was called "Nanboku-chō" (南北朝). This module uses the official Northern branch.

Also there has been two times during the period "Asuka" (飛鳥時代) with no era names, from 654/11/24 until 686/8/14 after Emperor Kōtoku death and from 686/10/1 until 701/5/3 after Emperor Tenmu's death just 2 months after his enthronement.

Thus if you want a Japanese date using era during those two periods, you will get and empty era.

More on this L<here|https://ja.wikipedia.org/wiki/%E5%85%83%E5%8F%B7%E4%B8%80%E8%A6%A7_(%E6%97%A5%E6%9C%AC)>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<DateTime>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd. DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
