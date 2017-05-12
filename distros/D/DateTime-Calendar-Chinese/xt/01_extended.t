use strict;
use utf8;
use Test::More;

use_ok "DateTime::Calendar::Chinese";

# This data taken from http://github.com/nekokak/p5-data-koyomi/
# Much much thanks to @nekokak

my $files = 'xt/01_extended/*.pl';
if ($ENV{PERL_DATETIME_CALENDAR_CHINESE_EXTENDED_TEST_FILES}) {
    $files = $ENV{PERL_DATETIME_CALENDAR_CHINESE_EXTENDED_TEST_FILES};
}

# need to extract random files or otherwise this test takes too long
my @files = glob($files);
if ( ! $ENV{RUN_EXTENDED_TESTS} ) {
    @files = map { $files[rand @files] } 1..5;
}

while ( my $file = shift @files ) {
    subtest $file => sub {
        my %koyomi = do $file;
        foreach my $date ( sort keys %koyomi ) {
            if ($date !~ /^(\d{4})-(\d{2})-(\d{2})$/) {
                die "Bad date: $date";
            }
        
            my $dt = DateTime->new(year => int($1), month => int($2), day => int($3), time_zone => 'Asia/Tokyo');
            my $ch = DateTime::Calendar::Chinese->from_object( object => $dt );
        
            ok $ch, "created chinese calendar for $date";
        
            my $data = $koyomi{$date};
            if ($data->{kyuureki} !~ /^(\d{4})-(\d{2})-(\d{2})$/) {
                die "Bad date: $data->{kyuureki}";
            }
        
            my ($ch_y, $ch_m, $ch_d) = (int($1), int($2), int($3));
        
            # XXX we store the year as a cycle of 60 years, but the original
            # data does not reflect that.
        #    is $ch->cycle_year, $ch_y, "year matches for $date <-> $data->{kyuureki} (got $ch_y, expect " . $ch->cycle_year . ")";
            is $ch->month, $ch_m, 
                sprintf( "month matches for %s <-> %s (got %d, expect %d)",
                    $date,
                    $data->{kyuureki},
                    $ch->month,
                    $ch_m
                );
            is $ch->day, $ch_d, 
                sprintf( "day matches for %s <-> %s (got %d, expect %d)",
                    $date,
                    $data->{kyuureki},
                    $ch->day,
                    $ch_d
                );
            is !! $ch->leap_month, !! $data->{leap_mon}, 
                sprintf( "leap month matches for %s <-> %s (got %d, expect %d)",
                    $date,
                    $data->{kyuureki},
                    !! $ch->leap_month,
                    !! $data->{leap_mon},
                );
        }
        done_testing;
    };
}

done_testing;
