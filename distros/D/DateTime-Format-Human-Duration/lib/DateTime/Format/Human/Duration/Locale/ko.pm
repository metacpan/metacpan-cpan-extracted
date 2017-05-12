package DateTime::Format::Human::Duration::Locale::ko;

use utf8;
use strict;
use warnings;

sub get_human_span_hashref {
    return {
        'no_oxford_comma' => 1,
        'no_time'         => '시간 없음',
        'and'             => q{},
        'year'            => '년',
        'years'           => '년',
        'month'           => '개월',
        'months'          => '개월',
        'week'            => '주',
        'weeks'           => '주',
        'day'             => '일',
        'days'            => '일',
        'hour'            => '시간',
        'hours'           => '시간',
        'minute'          => '분',
        'minutes'         => '분',
        'second'          => '초',
        'seconds'         => '초',
        'nanosecond'      => '나노초',
        'nanoseconds'     => '나노초',
    };
}

1;
