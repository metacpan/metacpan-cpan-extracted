use strict;
use warnings;
use Test::More;
use POSIX;
use Time::Local;
use Test::MockTime qw/set_fixed_time restore_time/;
require "./t/Req2PSGI.pm";
t::Req2PSGI->import();
use Apache::LogFormat::Compiler;
use HTTP::Request::Common;

sub time_difference {
    my $now = time();
    timegm(localtime($now)) - $now;    
}

eval {
    POSIX::tzset;
    die q!tzset is implemented on this Cygwin. But Windows can't change tz inside script! if $^O eq 'cygwin';
    die q!tzset is implemented on this Windows. But Windows can't change tz inside script! if $^O eq 'MSWin32';
};
if ( $@ ) {
    plan skip_all => $@;
}

my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my @timezones = ( 
    ['Australia/Darwin','+0930','+0930','+0930','+0930' ],
    ['Asia/Tokyo', '+0900','+0900','+0900','+0900'],
    ['UTC', '+0000','+0000','+0000','+0000'],
    ['Europe/London', '+0000','+0100','+0100','+0000'],
    ['America/New_York','-0500', '-0400', '-0400', '-0500']
);

for my $timezones (@timezones) {
    my ($timezone, @tz) = @$timezones;
    local $ENV{TZ} = $timezone;
    POSIX::tzset;
    my $log_handler = Apache::LogFormat::Compiler->new('%t');

    subtest "$timezone" => sub {
        my $i=0;
        for my $date ( ([10,1,2013], [10,5,2013], [15,8,2013], [15,11,2013]) ) {
            my ($day,$month,$year) = @$date;
            
            set_fixed_time(timelocal(0, 45, 12, $day, $month - 1, $year));
            my $tz = $tz[$i];

            my $log = $log_handler->log_line(
                t::Req2PSGI::req_to_psgi(GET "/"),
                [200,[],[q!OK!]],
            );
            
            my $month_name = $abbr[$month-1];
            is $log, "[$day/$month_name/2013:12:45:00 $tz]\n","$timezone $year/$month/$day";
            $i++;
        }
    };

    my $log_handler2 = Apache::LogFormat::Compiler->new('%{%z}t');
    subtest "$timezone custom format" => sub {
        my $i=0;
        for my $date ( ([10,1,2013], [10,5,2013], [15,8,2013], [15,11,2013]) ) {
            my ($day,$month,$year) = @$date;
            
            set_fixed_time(timelocal(0, 45, 12, $day, $month - 1, $year));
            my $tz = $tz[$i];

            my $log = $log_handler2->log_line(
                t::Req2PSGI::req_to_psgi(GET "/"),
                [200,[],[q!OK!]],
            );
            
            my $month_name = $abbr[$month-1];
            is $log, "[$tz]\n","custom format: $timezone $year/$month/$day";
            $i++;
        }
    };
    

}

done_testing();

