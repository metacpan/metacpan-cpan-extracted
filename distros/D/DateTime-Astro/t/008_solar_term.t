# see http://www.imo.net/data/solar for data
use strict;
use Test::More;
use constant MAX_DELTA_MINUTES => 180;
use constant NUM_SAMPLE => 6;

use_ok "DateTime::Astro", qw(solar_longitude);
use_ok "DateTime::Event::SolarTerm", qw(major_term minor_term major_term_after minor_term_after); 

# XXX - make sure to include dates in wide range
my @major_term_dates = 
    map { 
        my %args;
        @args{ qw(year month day hour minute time_zone) } =
            ( @$_, 0, 'UTC' );
        DateTime->new(%args);
    }
    (
        [ 2003,  1, 20, 13 ], # Dahan / Taikan
        [ 2003,  2, 19,  3 ], # Yushui / Usui
        [ 2003,  3, 21,  1 ], # Chunfen / Shunbun
        [ 2003,  4, 20, 13 ], # Guyu / Kokuu
        [ 2003,  5, 21, 12 ], # Xiaman / Shoman
        [ 2003,  6, 21, 22 ], # Xiazhi / Geshi
        [ 2003,  7, 23,  8 ], # Dashu / Taisho
        [ 2003,  8, 23, 16 ], # Chushu / Shosho
        [ 2003,  9, 23, 12 ], # Qiufen / Shubun
        [ 2003, 10, 23, 22 ], # Shuangjiang / Soko
        [ 2003, 11, 22, 19 ], # Xiaoxue / Shosetsu
        [ 2003, 12, 22,  9 ], # Dongzhi / Toji

        [ 2004,  1, 20, 19 ], # Dahan / Taikan
        [ 2004,  2, 19,  9 ], # Yushui / Usui
        [ 2004,  3, 20,  7 ], # Chunfen / Shunbun
        [ 2004,  4, 19, 19 ], # Guyu / Kokuu
        [ 2004,  5, 20, 19 ], # Xiaman / Shoman
        [ 2004,  6, 21,  3 ], # Xiazhi / Geshi
        [ 2004,  7, 22, 13 ], # Dashu / Taisho
        [ 2004,  8, 22, 21 ], # Chushu / Shosho
        [ 2004,  9, 22, 17 ], # Qiufen / Shubun 
        [ 2004, 10, 23,  3 ], # Shuangjiang / Soko
        [ 2004, 11, 22,  1 ], # Xiaoxue / Shosetsu
        [ 2004, 12, 21, 15 ], # Dongzhi / Toji


    );



my @minor_term_dates = 
    map { 
        my %args;
        @args{ qw(year month day hour minute) } = @$_;
        $args{minute} ||= 0;
        $args{time_zone} ||= 'UTC';
        DateTime->new(%args);
    }
    (
#        [ 2003, 1, 6 ],
#        [ 2003, 2, 4 ],
        [ 2004,  1, 6,  1 ], # Xiaohan / Shokan
        [ 2004,  2, 4, 13 ], # Lichun / Risshun
        [ 2004,  3, 5,  7 ], # Jingzhe / Keichitsu
        [ 2004,  4, 4, 11 ], # Qingming / Seimei
        [ 2004,  5, 5,  5 ], # Lixia / Rikka
        [ 2004,  6, 5,  7 ], # Mangzhong / Boshu
        [ 2004,  7, 6, 19 ], # Xiaoshu / Shosho
        [ 2004,  8, 7,  5 ], # Liqiu / Risshu
        [ 2004,  9, 7,  9 ], # Bailu / Hakuro
        [ 2004, 10, 8,  1 ], # Hanlu / Kanro
        [ 2004, 11, 7,  3 ], # Lidong / Ritto
        [ 2004, 12, 6, 21 ], # Dashue / Taisetsu
    );

sub do_major_terms
{
    my $solar_term = major_term();

    foreach my $dt (@major_term_dates) {
#        diag("Checking $dt");
        # if $dt is a solar term date, 7 days prior to this date is *definitely*
        # after the last solar term, but before the one expressed by $dt
        my $dt0 = $dt - DateTime::Duration->new(days => 7);

        my $next_solar_term = $solar_term->next($dt0);

        check_deltas($dt, $next_solar_term, "next major solar term from $dt0");
    
        # Same as before, but now we try $dt + 7 days
        my $dt1 = $dt + DateTime::Duration->new(days => 7);
        my $prev_solar_term = $solar_term->previous($dt1);
    
        check_deltas($dt, $prev_solar_term, "prev major solar term from $dt1");
    }
}

sub do_minor_terms
{
#    diag("Checking major term");
    foreach my $dt (map { $minor_term_dates[rand(@minor_term_dates)] } 1..NUM_SAMPLE) {
        # if $dt is a solar term date, 7 days prior to this date is *definitely*
        # after the last solar term, but before the one expressed by $dt
        my $dt0 = $dt - DateTime::Duration->new(days => 7);
    
        my $solar_term = minor_term();
        my $next_solar_term = $solar_term->next($dt0);
    
        check_deltas($dt, $next_solar_term, "next minor term from $dt0");
    
        # Same as before, but now we try $dt + 7 days
        my $dt1 = $dt + DateTime::Duration->new(days => 7);
        my $prev_solar_term = $solar_term->previous($dt1);
    
        check_deltas($dt, $prev_solar_term, "prev minor term from $dt1");
    }
}
    
sub check_deltas
{
    my($expected, $actual, $msg) = @_;

    my $diff = $expected - $actual;
    ok($diff);
    
    # make sure the deltas do not exceed 3 hours
    my %deltas = $diff->deltas;
    ok( $deltas{months} == 0 &&
        $deltas{days} == 0 &&
        abs($deltas{minutes}) < MAX_DELTA_MINUTES, $msg) or
    diag( "Expected solar term date was " . 
        $expected->strftime("%Y/%m/%d %T %Z") . " but instead we got " .
        $actual->strftime("%Y/%m/%d %T %Z") .
        " which is more than allowed delta of " .
        MAX_DELTA_MINUTES . " minutes" );

    my $lon_actual = solar_longitude( $actual );
    my $lon_expected = solar_longitude( $expected );
    my $lon_delta = abs($lon_actual - $lon_expected);

    ok ( 
        ($lon_delta > 330) ? 
            ($lon_delta > 359.5 && $lon_delta < 360.5) :
             $lon_delta < 0.5,
        "longitudes [actual = $lon_actual][expected = $lon_expected]"
    );
}

do_major_terms();
do_minor_terms();

{ # nekokak's tests

    my %major = (
        '2010' => ['2010-01-20','2010-02-19','2010-03-21','2010-04-20','2010-05-21','2010-06-21','2010-07-23','2010-08-23','2010-09-23','2010-10-23','2010-11-22','2010-12-22'], 
    );

    my %minor = (
        '2010' => ['2010-01-05','2010-02-04','2010-03-06','2010-04-05','2010-05-05','2010-06-06','2010-07-07','2010-08-07','2010-09-08','2010-10-08','2010-11-07','2010-12-07'], 
    );

    for my $y (qw/2010/) {
        my $dt = DateTime->new(year => $y, month => 1, day => 1, time_zone => 'Asia/Tokyo');
        for my $i (0..11) {
            my $major_dt = major_term_after($dt);
            $major_dt->set_time_zone('Asia/Tokyo');
            is $major_dt->ymd, $major{$y}->[$i], "Got $major_dt, expected $major{$y}->[$i]";

            my $minor_dt = minor_term_after($dt);
            $minor_dt->set_time_zone('Asia/Tokyo');
            is $minor_dt->ymd, $minor{$y}->[$i], "Got $minor_dt, expected $minor{$y}->[$i]"; 

            $dt = $major_dt->add(days => 1);
        }
    }
}

done_testing();
