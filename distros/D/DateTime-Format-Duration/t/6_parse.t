# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use warnings;
use DateTime;
use DateTime::Duration;
use DateTime::Format::Duration;

#########################

use Test::More tests=>24;


my $x = 0; # Test Counter

my $debug = 0;
$debug = 2 if join('',@ARGV) =~ /\!/;

test(
    ['%C', '20',        '2000-00-00 00:00:00.000000000', '%P%F %r.%N', 'Individual Components'],
    ['%d', '02',        '0000-00-02 00:00:00.000000000'],
    ['%e', '2',         '0000-00-02 00:00:00.000000000'],
    ['%H', '02',        '0000-00-00 02:00:00.000000000'],
    ['%I', '02',        '0000-00-00 02:00:00.000000000'],
    ['%j', '02',        '0000-00-02 00:00:00.000000000'],
    ['%k', '2',         '0000-00-00 02:00:00.000000000'],
    ['%l', '2',         '0000-00-00 02:00:00.000000000'],
    ['%m', '02',        '0000-02-00 00:00:00.000000000'],
    ['%M', '02',        '0000-00-00 00:02:00.000000000'],
    ['%n', '  ',        '0000-00-00 00:00:00.000000000'],
    ['%N', '2',         '0000-00-00 00:00:00.000000002'],
    ['%s', '2',         '0000-00-00 00:00:02.000000000'],
    ['%S', '02',        '0000-00-00 00:00:02.000000000'],
    ['%t', '  ',        '0000-00-00 00:00:00.000000000'],
    ['%u', '02',        '0000-00-02 00:00:00.000000000'],
    ['%V', '2',         '0000-00-14 00:00:00.000000000'],
    ['%W', '1.5',       '0000-00-10 12:00:00.000000000'],
    ['%y', '2',         '0002-00-00 00:00:00.000000000'],
    ['%Y', '0002',      '0002-00-00 00:00:00.000000000'],

    ['%F', '0002-03-04',    '0002-03-04 00:00:00.000000000', '%P%F %r.%N', 'Group Components'],
    ['%r', '02:03:04',      '0000-00-00 02:03:04.000000000'],
    ['%R', '02:03',         '0000-00-00 02:03:00.000000000'],
    ['%T', '-02:-03:-04',   '-0000-00-00 02:03:04.000000000'],

);



# ------------------ TESTING ROUTINES -------------------------

sub test {
    my @tests = @_;

    foreach my $test (@tests) {
        $x++;
        next unless in_range($x);

        diag($test->[4]) if $test->[4];
        is(
            DateTime::Format::Duration::strfduration(
                pattern => $test->[3] || '%P%F %r.%N',
                normalise => 1,
                duration => DateTime::Format::Duration::strpduration(
                    pattern  => $test->[0],
                    duration => $test->[1],
                    as_deltas=> 0,
                    debug    => $debug,
                ),
                debug => $debug,
            ),
            $test->[2],
            sprintf("Test %2d: %s as %s should be %s", $x, $test->[1], $test->[0], $test->[2]) # . (($test->[2]) ? sprintf(" (%s)",$test->[2]) : '')
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
        ($start, $end) = ($end, $start) if $end and $start and $end < $start;

        next if $start and $test and $start > $test;
        return 1 if $end and $test and $end > $test

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

