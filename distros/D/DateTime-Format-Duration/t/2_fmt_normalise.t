# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use warnings;
use DateTime;
use DateTime::Duration;
use DateTime::Format::Duration;

#########################

use Test::More tests=>52;


my $x = 0; # Test Counter


$strf = DateTime::Format::Duration->new(
    base => DateTime->new( year=> 2004, time_zone=>"Australia/Melbourne" ),
    pattern => '%P%F %r',
);
$strf->{diagnostic} = join('',@ARGV) =~ /\!/;

test(
    ['0000-00-00 00:00:01',     '0000-00-00 00:00:01'],
    ['0000-00-00 00:00:59',     '0000-00-00 00:00:59'],
    ['0000-00-00 00:00:60',     '0000-00-00 00:01:00'],
    ['0000-00-00 00:00:61',     '0000-00-00 00:01:01'],
    ['0000-00-00 00:00:119',    '0000-00-00 00:01:59'],
    ['0000-00-00 00:00:120',    '0000-00-00 00:02:00'],
    ['0000-00-00 00:00:121',    '0000-00-00 00:02:01'],

    ['0000-00-00 00:01:00',     '0000-00-00 00:01:00'],
    ['0000-00-00 00:59:00',     '0000-00-00 00:59:00'],
    ['0000-00-00 00:60:00',     '0000-00-00 01:00:00'],
    ['0000-00-00 00:61:00',     '0000-00-00 01:01:00'],
    ['0000-00-00 00:01:59',     '0000-00-00 00:01:59'],
    ['0000-00-00 00:01:60',     '0000-00-00 00:02:00'],
    ['0000-00-00 00:01:61',     '0000-00-00 00:02:01'],
    ['0000-00-00 00:59:60',     '0000-00-00 01:00:00'],
    ['0000-00-00 00:60:60',     '0000-00-00 01:01:00'],

    ['0000-00-00 01:00:00',     '0000-00-00 01:00:00'],
    ['0000-00-00 23:00:00',     '0000-00-00 23:00:00'],
    ['0000-00-00 24:00:00',     '0000-00-01 00:00:00'],
    ['0000-00-00 25:00:00',     '0000-00-01 01:00:00'],
    ['0000-00-00 01:59:00',     '0000-00-00 01:59:00'],
    ['0000-00-00 01:60:00',     '0000-00-00 02:00:00'],
    ['0000-00-00 01:61:00',     '0000-00-00 02:01:00'],
    ['0000-00-00 23:60:00',     '0000-00-01 00:00:00'],
    ['0000-00-00 24:60:00',     '0000-00-01 01:00:00'],

    ['0000-00-00 00:00:86400',  '0000-00-01 00:00:00'], # Overflows
    ['0000-00-00 00:1440:00',   '0000-00-01 00:00:00'],
    ['0000-00-00 240:00:00',    '0000-00-10 00:00:00',],
    ['0000-00-45 00:00:00',     '0000-01-14 00:00:00',],
    ['0000-240-00 00:00:00',    '0020-00-00 00:00:00',],
    ['0000-00-00 00:00:-86400', '-0000-00-01 00:00:00'], # Underflows
    ['0000-00-00 00:-1440:00',  '-0000-00-01 00:00:00'],
    ['0000-00-00 -240:00:00',   '-0000-00-10 00:00:00',],
    ['0000-00--45 00:00:00',    '-0000-01-14 00:00:00',],
    ['0000--240-00 00:00:00',   '-0020-00-00 00:00:00',],

    ['0000-00-00 00:00:-01',    '-0000-00-00 00:00:01'],
    ['0000-00-00 00:00:-59',    '-0000-00-00 00:00:59'],
    ['0000-00-00 00:00:-60',    '-0000-00-00 00:01:00'],
    ['0000-00-00 00:00:-61',    '-0000-00-00 00:01:01'],

    ['0000-00-00 -01:01:-01',   '-0000-00-00 00:59:01'], # Mixed positivity

);


# DST Changeovers are easier to see if we use better bases:
$strf->set_base(DateTime->new( year=> 2004, month=>3, day=>27, time_zone=>"Australia/Melbourne" ));
test(
    ['0000-00-00 48:00:00',     '0000-00-01 23:00:00', 'DST ends, Day is 25 hours long'],
    ['0000-00-02 -48:00:00',    '0000-00-00 01:00:00'],
    ['0000-00-02 00:00:00',     '0000-00-02 00:00:00'], # days are days, they don't change
    ['0000-00-00 24:00:00',     '0000-00-01 00:00:00'], # hours not crossing the DST don't change

);

$strf->set_base(DateTime->new( year=> 2004, month=>10, day=>30, time_zone=>"Australia/Melbourne" ));
test(
    ['0000-00-00 48:00:00',     '0000-00-02 01:00:00', 'DST starts, Day is 23 hours long'],
    ['0000-00-02 -48:00:00',    '-0000-00-00 01:00:00'],
    ['0000-00-02 00:00:00',     '0000-00-02 00:00:00'], # days are days, they don't change
    ['0000-00-00 24:00:00',     '0000-00-01 00:00:00'], # hours not crossing the DST don't change
);


# Leap Seconds are easier to see if we use better bases:
$strf->set_base(DateTime->new( year=> 1998, month=>12, day=>31, hour=>23, minute=>58, time_zone=>"UTC" ));
test(
    ['0000-00-00 00:01:120',    '0000-00-00 00:02:59', 'Leap Second adds an extra second to one of the minutes.'],
    ['0000-00-00 00:01:60',     '0000-00-00 00:01:60'],
    ['0000-00-00 00:03:00',     '0000-00-00 00:03:00'],
    ['0000-00-00 00:00:60',     '0000-00-00 00:01:00'],
);





# ------------------ TESTING ROUTINES -------------------------

sub test {
    my @tests = @_;

    foreach my $test (@tests) {
        my $w = ($x++ < 9) ? 22 : 21;
        next unless in_range($x);

        diag($test->[2]) if $test->[2];
        is(
            $strf->format_duration_from_deltas(
                $strf->parse_duration_as_deltas(
                    $test->[0]
                )
            ),
            $test->[1],
            sprintf("Test %2d: %${w}s should %s %s", $x, $test->[0], ($test->[0] eq $test->[1]) ? 'stay  ':'become', $test->[1]) # . (($test->[2]) ? sprintf(" (%s)",$test->[2]) : '')
        ) or diag( "If you send an error report, please include the output of:\n $^X $0 $x!" );
    }
}

sub in_range {
    # see if this test is in our list of tests:
    return 1 unless $ARGV[0];

    my $test = shift;

    $argv = join(',', @ARGV);
    $argv=~s/,\.\.,/../g;
    $argv=~s/,,/,/g;

    $argv=~s/\!//;

    return 1 if $argv=~/\b$test\b/;

    foreach my $part( split(/,\s*/, $argv) ) {
        my ($start, $end) = $part =~ /(\d+)\s*\.\.\s*(\d+)/;
        ($start, $end) = ($end, $start) if $end < $start;

        next if $start > $test;
        return 1 if $end > $test

    }

    return 0;
}

sub Dump {
    eval{
        require Data::Dumper
    };
    return "<Couldn't load Data::Dumper>" if $@;
    return Data::Dumper::Dumper(@_)
}



#    Oct 30 (24 hrs)    #    Oct 31 (25 hrs)     #     Nov 1 (24 hrs)    #
#-----------|-----------#------------|-----------#-----------|-----------#

# 48 Hours == 1 day, 24 hours:
#-----------------------------------------------#
#---- 1 day ------------#------ 24 hours -------#

# 2 Days, -48 Hours == 1 hour:
#------------------- 2 days --------------------#
 #------------------ 48 hours ------------------#
# 1 hour

