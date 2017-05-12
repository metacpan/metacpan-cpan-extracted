#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true);

use DateTime::Format::Natural;
use DateTime::Format::Natural::Test qw($case_strings);
use Test::More;

my @strings = (
    { 'see you next thurs for coffee',                      => [ 'next thu'                                ] },
    { "I'll meet you on 15th march at the cinema"           => [ '15th march'                              ] },
    { 'payment is due in 30 days'                           => [ 'in 30 days'                              ] },
    { 'johann sebastian bach was born 21/03/1685'           => [ '21/03/1685'                              ] },
    { '09/11/1989 18:57 was a historic moment'              => [ '09/11/1989 18:57'                        ] },
    { 'readings start at 20:00 and 22:00'                   => [ qw(20:00 22:00)                           ] },
    { 'conference will take place from wednesday to friday' => [ 'wednesday to friday'                     ] },
    { 'free days are friday, saturday and sunday'           => [ qw(friday saturday sunday)                ] },
    { 'system is stopped friday; started early monday'      => [ qw(friday monday)                         ] },
    { '02/03/2011 midnight and 02/03/2011 noon'             => [ '02/03/2011 midnight', '02/03/2011 noon'  ] },
    { '1969-07-20 and now'                                  => [ qw(1969-07-20 now)                        ] },
    { '6:00 compared to 6'                                  => [ '6:00'                                    ] }, # ambiguous token missing
    { 'yesterday to today and today to tomorrow'            => [ 'yesterday to today', 'today to tomorrow' ] },
    { 'tuesday wednesday'                                   => [ qw(tuesday wednesday)                     ] },
    { 'we will stay for 3 days at the venue'                => [ 'for 3 days'                              ] },
    { 'from first to last day of october forms a month'     => [ 'first to last day of october'            ] },
    { '26 oct at 10am to 11:00 is spare time'               => [ '26 oct 10am to 11:00'                    ] },
    { '3 days ago to for 3 days'                            => [ '3 days ago', 'for 3 days'                ] }, # separate for <count> <unit> grammar duration
);

my @expanded = (
    { 'started work at 6am last day' => [ '6am last day' ] },
);

my @rewrite = (
    { '6 am'                  => [ '6am'                ] },
    { '8 pm'                  => [ '8pm'                ] },
    { 'yesterday at noon'     => [ 'yesterday noon'     ] },
    { 'yesterday at midnight' => [ 'yesterday midnight' ] },
    { 'today at 6 am'         => [ 'today 6am'          ] },
    { 'today at 8 pm'         => [ 'today 8pm'          ] },
    { 'tomorrow at 6'         => [ 'tomorrow 6:00'      ] },
    { 'tomorrow at 20'        => [ 'tomorrow 20:00'     ] },
);

my @punctuation = (
    { 'dec 18, 1987'   => [ 'dec 18 1987'      ] },
    { 'sunday, monday' => [ 'sunday', 'monday' ] },
    { 'sunday; monday' => [ 'sunday', 'monday' ] },
    { 'sunday. monday' => [ 'sunday', 'monday' ] },
    { ',tuesday'       => [ 'tuesday'          ] },
    { ';tuesday'       => [ 'tuesday'          ] },
    { '.tuesday'       => [ 'tuesday'          ] },
    { 'wednesday,'     => [ 'wednesday'        ] },
    { 'wednesday;'     => [ 'wednesday'        ] },
    { 'wednesday.'     => [ 'wednesday'        ] },
    { ' ,thursday'     => [ 'thursday'         ] },
    { 'thursday, '     => [ 'thursday'         ] },
);

my @spaces = (
    { 'wednesday  this  week'         => [ 'wednesday this week'      ] },
    { 'first  to  last  day  of  jan' => [ 'first to last day of jan' ] },
    { '2013-01-16  8pm  to  10pm'     => [ '2013-01-16 8pm to 10pm'   ] },
);

# sanity checks
my @duration = (
    { 'monday to to friday'       => [ qw(monday friday)          ] },
    { 'saturday to'               => [ 'saturday'                 ] },
    { 'to saturday'               => [ 'saturday'                 ] },
    { 'this year to next year to' => [ 'this year to next year'   ] },
    { 'feb to may to oct to dec'  => [ 'feb to may', 'oct to dec' ] },
);

my @durations = (
# combined
    { 'first to last day of september'  => [ 'first to last day of september' ] },
    { 'first to last day of 2008'       => [ 'first to last day of 2008'      ] },
# relative
    { '2009-03-10 at 9:00 to 11:00'     => [ '2009-03-10 9:00 to 11:00'       ] },
    { '26 oct 10am to 11:00'            => [ '26 oct 10am to 11:00'           ] },
    { 'may 2nd to 5th'                  => [ 'may 2nd to 5th'                 ] },
    { 'jan 1 to 2nd'                    => [ 'jan 1 to 2nd'                   ] },
    { '16:00 6 nov to 17:00'            => [ '16:00 6 nov to 17:00'           ] },
    { '24 dec to 26'                    => [ '24 dec to 26'                   ] },
    { '100th day to 200th'              => [ '100th day to 200th'             ] },
    { '30th to 31st dec'                => [ '30th to 31st dec'               ] },
    { '30th to dec 31st'                => [ '30th to dec 31st'               ] },
    { '21:00 to mar 3 22:00'            => [ '21:00 to mar 3 22:00'           ] },
    { '21:00 to 22:00 mar 3'            => [ '21:00 to 22:00 mar 3'           ] },
    { '10th to 20th day'                => [ '10th to 20th day'               ] },
# rewrite
    { 'today at 5pm to tomorrow at 6am' => [ 'today 5pm to tomorrow 6am'      ] },
    { 'monday 7 am to friday 5 pm'      => [ 'monday 7am to friday 5pm'       ] },
    { 'tues to thurs'                   => [ 'tue to thu'                     ] },
    { 'sat @ 2 to sun @ 6'              => [ 'sat 2:00 to sun 6:00'           ] },
);

foreach my $set (\@strings, \@expanded, \@rewrite, \@punctuation, \@spaces, \@duration, \@durations) {
    compare($set);
}

sub compare
{
    my $aref = shift;

    foreach my $href (@$aref) {
        my $key = (keys %$href)[0];
        foreach my $string ($case_strings->($key)) {
            compare_strings($string, $href->{$key});
        }
    }
}

sub compare_strings
{
    my ($string, $result) = @_;

    my $parser = DateTime::Format::Natural->new;
    my @expressions = $parser->extract_datetime($string);

    if (@expressions) {
        my $equal = is_deeply([ map lc, @expressions ], $result, "$string (extracting)");
        SKIP: {
            skip 'extracted expressions differ', 1 unless $equal;
            # eval in order to avoid fatal errors on some older perls
            my $parses = eval true;
            foreach my $expression (@expressions) {
                $parser->parse_datetime_duration($expression);
                $parses &= $parser->success;
            }
            ok($parses, "$string (parsing)");
        }
    }
    else {
        fail($string);
    }
}

done_testing();
