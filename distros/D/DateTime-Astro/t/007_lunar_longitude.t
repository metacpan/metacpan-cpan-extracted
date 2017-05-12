use strict;
use Test::More;
use Test::Exception;
use DateTime::Astro qw(moment new_moon_after new_moon_before);

# 19:00 nekokak: ちなみに１９９８年１月２８日１５時０分５０秒４は新月です！
# lestrrat: これは日本時間だから、UTCだと9時間ほどずれる

lives_ok {
    my $dt = new_moon_after( DateTime->new( year => 1998, month => 1, day => 27 ) );
    is $dt->year, 1998;
    is $dt->month, 1;
    is $dt->day, 28;
    is $dt->hour, 6;
    is $dt->minute, 1; # XXXX
} "sanity";

sub datetime {
    return unless $_[0];
    my ($n, $y, $m, $d, $H, $M, $S) = @{$_[0]};
    return DateTime->new(
        time_zone => 'UTC',
        year => $y,
        month => $m,
        day => $d,
        hour => $H,
        minute => $M,
        second => $S || 0,
    );
}

lives_ok {
    my @data = (map { [ split /\s+/, $_ ] } <DATA>);

    my @prev;
    my $dt = datetime(do { my $data = shift @data; push @prev, $data; $data });

    while (my $next = datetime(do { my $data = shift @data; push @prev, $data if $data; $data })) {
        if (moment($next) - moment($dt) < 29.5) {
            my $got = new_moon_after( $dt );
            my $delta = abs(moment($got) - moment($next));
            ok $delta < 1, "new moon after $dt -> $got (expected $next) delta = $delta";
        }
        $dt = $next;
    }

    $dt = datetime(pop @prev);
    while (my $prev = datetime(pop @prev)) {
        if (moment($dt) - moment($prev) < 29.5) {
            my $got = new_moon_before( $dt ->subtract( days => 1 ) );
            my $delta = abs(moment($prev) - moment($got));
            ok $delta < 1, "new moon before $dt -> $got (expected $prev) delta = $delta";
        }
        $dt = $prev;
    }
};

done_testing;

__DATA__
21014 1700  1 20  4 20
21015 1700  2 18 23 33
21016 1700  3 20 16 46
21017 1700  4 19  6 51
21018 1700  5 18 17 45
21019 1700  6 17  2 14
21020 1700  7 16  9 32
21021 1700  8 14 16 45
21022 1700  9 13  0 47
21023 1700 10 12 10 15
21024 1700 11 10 21 44
21025 1700 12 10 11 44
24712 1999  1 17 15 46
24713 1999  2 16  6 39
24714 1999  3 17 18 48
24715 1999  4 16  4 22
24716 1999  5 15 12  5
24717 1999  6 13 19  3
24718 1999  7 13  2 24
24719 1999  8 11 11  8
24720 1999  9  9 22  2
24721 1999 10  9 11 34
24722 1999 11  8  3 53
24723 1999 12  7 22 32
24724 2000  1  6 18 14
24725 2000  2  5 13  3
24726 2000  3  6  5 17
24727 2000  4  4 18 12
24728 2000  5  4  4 12
24729 2000  6  2 12 14
24730 2000  7  1 19 20
24731 2000  7 31  2 25
24732 2000  8 29 10 19
24733 2000  9 27 19 53
24734 2000 10 27  7 58
24735 2000 11 25 23 11
24736 2000 12 25 17 22
