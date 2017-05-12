use strict;
use warnings;
use Test::More qw(no_plan);

BEGIN { use_ok('Date::Holidays::CA', qw(:all)) };

# correctness tests.  
#     do the holidays actually fall on the days we say they do?
#     do we get back the right holidays for the province we give?
#     do we get back the holiday names in the right language?

# load up a table of representative years and see if the module's
# output matches.

my %CANONICAL_HOLIDAYS_FOR  = canonical_holidays(); 
my %SUBSTITUTE_HOLIDAYS_FOR = substitute_holidays(); 

foreach my $year (keys %CANONICAL_HOLIDAYS_FOR) {
    my $calendar = Date::Holidays::CA->new(
        {language => 'EN', province => 'CA'}
    );
    my $holidays_ref = $calendar->holidays($year); 

    # first check that we've generated the correct number of holidays
    is ( 
         scalar keys %{$holidays_ref},  
         scalar keys %{$CANONICAL_HOLIDAYS_FOR{$year}},
         "correct number of holidays for $year"
    );

    # now check the individual dates
    foreach my $holiday_name (keys %{$CANONICAL_HOLIDAYS_FOR{$year}}) {
        my ($canon_year, $canon_month, $canon_day) = 
            split '-', $CANONICAL_HOLIDAYS_FOR{$year}->{$holiday_name}; 

        is( 
            $holidays_ref->{$canon_month . $canon_day},
            $holiday_name,
            "correct date for $year $holiday_name"
        );
    }
}


## pseudo-DATA section ############################################

sub canonical_holidays { 
    1583 => {
        'New Year\'s Day' =>               '1583-01-01',
        'Good Friday' =>                   '1583-04-08',
        'Easter Monday' =>                 '1583-04-11',
        'Victoria Day' =>                  '1583-05-23',
        'Canada Day' =>                    '1583-07-01',
        'Labour Day' =>                    '1583-09-05',
        'Thanksgiving Day' =>              '1583-10-10',
        'Remembrance Day' =>               '1583-11-11',
        'Christmas Day' =>                 '1583-12-25',
        'Boxing Day' =>                    '1583-12-26',
    },

    1584 => {
        'New Year\'s Day' =>               '1584-01-01',
        'Good Friday' =>                   '1584-03-30',
        'Easter Monday' =>                 '1584-04-02',
        'Victoria Day' =>                  '1584-05-21',
        'Canada Day' =>                    '1584-07-01',
        'Labour Day' =>                    '1584-09-03',
        'Thanksgiving Day' =>              '1584-10-08',
        'Remembrance Day' =>               '1584-11-11',
        'Christmas Day' =>                 '1584-12-25',
        'Boxing Day' =>                    '1584-12-26',
    },

    1969 => {
        'New Year\'s Day' =>               '1969-01-01',
        'Good Friday' =>                   '1969-04-04',
        'Easter Monday' =>                 '1969-04-07',
        'Victoria Day' =>                  '1969-05-19',
        'Canada Day' =>                    '1969-07-01',
        'Labour Day' =>                    '1969-09-01',
        'Thanksgiving Day' =>              '1969-10-13',
        'Remembrance Day' =>               '1969-11-11',
        'Christmas Day' =>                 '1969-12-25',
        'Boxing Day' =>                    '1969-12-26',
    },

    1970 => {
        'New Year\'s Day' =>               '1970-01-01',
        'Good Friday' =>                   '1970-03-27',
        'Easter Monday' =>                 '1970-03-30',
        'Victoria Day' =>                  '1970-05-18',
        'Canada Day' =>                    '1970-07-01',
        'Labour Day' =>                    '1970-09-07',
        'Thanksgiving Day' =>              '1970-10-12',
        'Remembrance Day' =>               '1970-11-11',
        'Christmas Day' =>                 '1970-12-25',
        'Boxing Day' =>                    '1970-12-26',
    },

    1971 => {
        'New Year\'s Day' =>               '1971-01-01',
        'Good Friday' =>                   '1971-04-09',
        'Easter Monday' =>                 '1971-04-12',
        'Victoria Day' =>                  '1971-05-24',
        'Canada Day' =>                    '1971-07-01',
        'Labour Day' =>                    '1971-09-06',
        'Thanksgiving Day' =>              '1971-10-11',
        'Remembrance Day' =>               '1971-11-11',
        'Christmas Day' =>                 '1971-12-25',
        'Boxing Day' =>                    '1971-12-26',
    },

    1999 => {
        'New Year\'s Day' =>               '1999-01-01',
        'Good Friday' =>                   '1999-04-02',
        'Easter Monday' =>                 '1999-04-05',
        'Victoria Day' =>                  '1999-05-24',
        'Canada Day' =>                    '1999-07-01',
        'Labour Day' =>                    '1999-09-06',
        'Thanksgiving Day' =>              '1999-10-11',
        'Remembrance Day' =>               '1999-11-11',
        'Christmas Day' =>                 '1999-12-25',
        'Boxing Day' =>                    '1999-12-26',
    },

    2000 => {
        'New Year\'s Day' =>               '2000-01-01',
        'Good Friday' =>                   '2000-04-21',
        'Easter Monday' =>                 '2000-04-24',
        'Victoria Day' =>                  '2000-05-22',
        'Canada Day' =>                    '2000-07-01',
        'Labour Day' =>                    '2000-09-04',
        'Thanksgiving Day' =>              '2000-10-09',
        'Remembrance Day' =>               '2000-11-11',
        'Christmas Day' =>                 '2000-12-25',
        'Boxing Day' =>                    '2000-12-26',
    },

    2001 => {
        'New Year\'s Day' =>               '2001-01-01',
        'Good Friday' =>                   '2001-04-13',
        'Easter Monday' =>                 '2001-04-16',
        'Victoria Day' =>                  '2001-05-21',
        'Canada Day' =>                    '2001-07-01',
        'Labour Day' =>                    '2001-09-03',
        'Thanksgiving Day' =>              '2001-10-08',
        'Remembrance Day' =>               '2001-11-11',
        'Christmas Day' =>                 '2001-12-25',
        'Boxing Day' =>                    '2001-12-26',
    },

    2002 => {
        'New Year\'s Day' =>               '2002-01-01',
        'Good Friday' =>                   '2002-03-29',
        'Easter Monday' =>                 '2002-04-01',
        'Victoria Day' =>                  '2002-05-20',
        'Canada Day' =>                    '2002-07-01',
        'Labour Day' =>                    '2002-09-02',
        'Thanksgiving Day' =>              '2002-10-14',
        'Remembrance Day' =>               '2002-11-11',
        'Christmas Day' =>                 '2002-12-25',
        'Boxing Day' =>                    '2002-12-26',
    },

    2003 => {
        'New Year\'s Day' =>               '2003-01-01',
        'Good Friday' =>                   '2003-04-18',
        'Easter Monday' =>                 '2003-04-21',
        'Victoria Day' =>                  '2003-05-19',
        'Canada Day' =>                    '2003-07-01',
        'Labour Day' =>                    '2003-09-01',
        'Thanksgiving Day' =>              '2003-10-13',
        'Remembrance Day' =>               '2003-11-11',
        'Christmas Day' =>                 '2003-12-25',
        'Boxing Day' =>                    '2003-12-26',
    },

    2004 => {
        'New Year\'s Day' =>               '2004-01-01',
        'Good Friday' =>                   '2004-04-09',
        'Easter Monday' =>                 '2004-04-12',
        'Victoria Day' =>                  '2004-05-24',
        'Canada Day' =>                    '2004-07-01',
        'Labour Day' =>                    '2004-09-06',
        'Thanksgiving Day' =>              '2004-10-11',
        'Remembrance Day' =>               '2004-11-11',
        'Christmas Day' =>                 '2004-12-25',
        'Boxing Day' =>                    '2004-12-26',
    },

    2005 => {
        'New Year\'s Day' =>               '2005-01-01',
        'Good Friday' =>                   '2005-03-25',
        'Easter Monday' =>                 '2005-03-28',
        'Victoria Day' =>                  '2005-05-23',
        'Canada Day' =>                    '2005-07-01',
        'Labour Day' =>                    '2005-09-05',
        'Thanksgiving Day' =>              '2005-10-10',
        'Remembrance Day' =>               '2005-11-11',
        'Christmas Day' =>                 '2005-12-25',
        'Boxing Day' =>                    '2005-12-26',
    },

    2006 => {
        'New Year\'s Day' =>               '2006-01-01',
        'Good Friday' =>                   '2006-04-14',
        'Easter Monday' =>                 '2006-04-17',
        'Victoria Day' =>                  '2006-05-22',
        'Canada Day' =>                    '2006-07-01',
        'Labour Day' =>                    '2006-09-04',
        'Thanksgiving Day' =>              '2006-10-09',
        'Remembrance Day' =>               '2006-11-11',
        'Christmas Day' =>                 '2006-12-25',
        'Boxing Day' =>                    '2006-12-26',
    },

    2007 => {
        'New Year\'s Day' =>               '2007-01-01',
        'Good Friday' =>                   '2007-04-06',
        'Easter Monday' =>                 '2007-04-09',
        'Victoria Day' =>                  '2007-05-21',
        'Canada Day' =>                    '2007-07-01',
        'Labour Day' =>                    '2007-09-03',
        'Thanksgiving Day' =>              '2007-10-08',
        'Remembrance Day' =>               '2007-11-11',
        'Christmas Day' =>                 '2007-12-25',
        'Boxing Day' =>                    '2007-12-26',
    },

    2037 => {
        'New Year\'s Day' =>               '2037-01-01',
        'Good Friday' =>                   '2037-04-03',
        'Easter Monday' =>                 '2037-04-06',
        'Victoria Day' =>                  '2037-05-18',
        'Canada Day' =>                    '2037-07-01',
        'Labour Day' =>                    '2037-09-07',
        'Thanksgiving Day' =>              '2037-10-12',
        'Remembrance Day' =>               '2037-11-11',
        'Christmas Day' =>                 '2037-12-25',
        'Boxing Day' =>                    '2037-12-26',
    },

    2038 => {
        'New Year\'s Day' =>               '2038-01-01',
        'Good Friday' =>                   '2038-04-23',
        'Easter Monday' =>                 '2038-04-26',
        'Victoria Day' =>                  '2038-05-24',
        'Canada Day' =>                    '2038-07-01',
        'Labour Day' =>                    '2038-09-06',
        'Thanksgiving Day' =>              '2038-10-11',
        'Remembrance Day' =>               '2038-11-11',
        'Christmas Day' =>                 '2038-12-25',
        'Boxing Day' =>                    '2038-12-26',
    },

    2039 => {
        'New Year\'s Day' =>               '2039-01-01',
        'Good Friday' =>                   '2039-04-08',
        'Easter Monday' =>                 '2039-04-11',
        'Victoria Day' =>                  '2039-05-23',
        'Canada Day' =>                    '2039-07-01',
        'Labour Day' =>                    '2039-09-05',
        'Thanksgiving Day' =>              '2039-10-10',
        'Remembrance Day' =>               '2039-11-11',
        'Christmas Day' =>                 '2039-12-25',
        'Boxing Day' =>                    '2039-12-26',
    },

    2298 => {
        'New Year\'s Day' =>               '2298-01-01',
        'Good Friday' =>                   '2298-04-01',
        'Easter Monday' =>                 '2298-04-04',
        'Victoria Day' =>                  '2298-05-23',
        'Canada Day' =>                    '2298-07-01',
        'Labour Day' =>                    '2298-09-05',
        'Thanksgiving Day' =>              '2298-10-10',
        'Remembrance Day' =>               '2298-11-11',
        'Christmas Day' =>                 '2298-12-25',
        'Boxing Day' =>                    '2298-12-26',
    },

    2299 => {
        'New Year\'s Day' =>               '2299-01-01',
        'Good Friday' =>                   '2299-04-14',
        'Easter Monday' =>                 '2299-04-17',
        'Victoria Day' =>                  '2299-05-22',
        'Canada Day' =>                    '2299-07-01',
        'Labour Day' =>                    '2299-09-04',
        'Thanksgiving Day' =>              '2299-10-09',
        'Remembrance Day' =>               '2299-11-11',
        'Christmas Day' =>                 '2299-12-25',
        'Boxing Day' =>                    '2299-12-26',
    },

};


sub substitute_holidays { 
    1583 => {
        'New Year\'s Day' =>               '1583-01-03',
        'Good Friday' =>                   '1583-04-08',
        'Easter Monday' =>                 '1583-04-11',
        'Victoria Day' =>                  '1583-05-23',
        'Canada Day' =>                    '1583-07-01',
        'Labour Day' =>                    '1583-09-05',
        'Thanksgiving Day' =>              '1583-10-10',
        'Remembrance Day' =>               '1583-11-11',
        'Christmas Day' =>                 '1583-12-26',
        'Boxing Day' =>                    '1583-12-27',
    },

    1584 => {
        'New Year\'s Day' =>               '1584-01-02',
        'Good Friday' =>                   '1584-03-30',
        'Easter Monday' =>                 '1584-04-02',
        'Victoria Day' =>                  '1584-05-21',
        'Canada Day' =>                    '1584-07-02',
        'Labour Day' =>                    '1584-09-03',
        'Thanksgiving Day' =>              '1584-10-08',
        'Remembrance Day' =>               '1584-11-12',
        'Christmas Day' =>                 '1584-12-25',
        'Boxing Day' =>                    '1584-12-26',
    },

    1969 => {
        'New Year\'s Day' =>               '1969-01-01',
        'Good Friday' =>                   '1969-04-04',
        'Easter Monday' =>                 '1969-04-07',
        'Victoria Day' =>                  '1969-05-19',
        'Canada Day' =>                    '1969-07-01',
        'Labour Day' =>                    '1969-09-01',
        'Thanksgiving Day' =>              '1969-10-13',
        'Remembrance Day' =>               '1969-11-11',
        'Christmas Day' =>                 '1969-12-25',
        'Boxing Day' =>                    '1969-12-26',
    },

    1970 => {
        'New Year\'s Day' =>               '1970-01-01',
        'Good Friday' =>                   '1970-03-27',
        'Easter Monday' =>                 '1970-03-30',
        'Victoria Day' =>                  '1970-05-18',
        'Canada Day' =>                    '1970-07-01',
        'Labour Day' =>                    '1970-09-07',
        'Thanksgiving Day' =>              '1970-10-12',
        'Remembrance Day' =>               '1970-11-11',
        'Christmas Day' =>                 '1970-12-25',
        'Boxing Day' =>                    '1970-12-28',
    },

    1971 => {
        'New Year\'s Day' =>               '1971-01-01',
        'Good Friday' =>                   '1971-04-09',
        'Easter Monday' =>                 '1971-04-12',
        'Victoria Day' =>                  '1971-05-24',
        'Canada Day' =>                    '1971-07-01',
        'Labour Day' =>                    '1971-09-06',
        'Thanksgiving Day' =>              '1971-10-11',
        'Remembrance Day' =>               '1971-11-11',
        'Christmas Day' =>                 '1971-12-27',
        'Boxing Day' =>                    '1971-12-28',
    },

    1999 => {
        'New Year\'s Day' =>               '1999-01-01',
        'Good Friday' =>                   '1999-04-02',
        'Easter Monday' =>                 '1999-04-05',
        'Victoria Day' =>                  '1999-05-24',
        'Canada Day' =>                    '1999-07-01',
        'Labour Day' =>                    '1999-09-06',
        'Thanksgiving Day' =>              '1999-10-11',
        'Remembrance Day' =>               '1999-11-11',
        'Christmas Day' =>                 '1999-12-27',
        'Boxing Day' =>                    '1999-12-28',
    },

    2000 => {
        'New Year\'s Day' =>               '2000-01-03',
        'Good Friday' =>                   '2000-04-21',
        'Easter Monday' =>                 '2000-04-24',
        'Victoria Day' =>                  '2000-05-22',
        'Canada Day' =>                    '2000-07-03',
        'Labour Day' =>                    '2000-09-04',
        'Thanksgiving Day' =>              '2000-10-09',
        'Remembrance Day' =>               '2000-11-13',
        'Christmas Day' =>                 '2000-12-25',
        'Boxing Day' =>                    '2000-12-26',
    },

    2001 => {
        'New Year\'s Day' =>               '2001-01-01',
        'Good Friday' =>                   '2001-04-13',
        'Easter Monday' =>                 '2001-04-16',
        'Victoria Day' =>                  '2001-05-21',
        'Canada Day' =>                    '2001-07-02',
        'Labour Day' =>                    '2001-09-03',
        'Thanksgiving Day' =>              '2001-10-08',
        'Remembrance Day' =>               '2001-11-12',
        'Christmas Day' =>                 '2001-12-25',
        'Boxing Day' =>                    '2001-12-26',
    },

    2002 => {
        'New Year\'s Day' =>               '2002-01-01',
        'Good Friday' =>                   '2002-03-29',
        'Easter Monday' =>                 '2002-04-01',
        'Victoria Day' =>                  '2002-05-20',
        'Canada Day' =>                    '2002-07-01',
        'Labour Day' =>                    '2002-09-02',
        'Thanksgiving Day' =>              '2002-10-14',
        'Remembrance Day' =>               '2002-11-11',
        'Christmas Day' =>                 '2002-12-25',
        'Boxing Day' =>                    '2002-12-26',
    },

    2003 => {
        'New Year\'s Day' =>               '2003-01-01',
        'Good Friday' =>                   '2003-04-18',
        'Easter Monday' =>                 '2003-04-21',
        'Victoria Day' =>                  '2003-05-19',
        'Canada Day' =>                    '2003-07-01',
        'Labour Day' =>                    '2003-09-01',
        'Thanksgiving Day' =>              '2003-10-13',
        'Remembrance Day' =>               '2003-11-11',
        'Christmas Day' =>                 '2003-12-25',
        'Boxing Day' =>                    '2003-12-26',
    },

    2004 => {
        'New Year\'s Day' =>               '2004-01-01',
        'Good Friday' =>                   '2004-04-09',
        'Easter Monday' =>                 '2004-04-12',
        'Victoria Day' =>                  '2004-05-24',
        'Canada Day' =>                    '2004-07-01',
        'Labour Day' =>                    '2004-09-06',
        'Thanksgiving Day' =>              '2004-10-11',
        'Remembrance Day' =>               '2004-11-11',
        'Christmas Day' =>                 '2004-12-27',
        'Boxing Day' =>                    '2004-12-28',
    },

    2005 => {
        'New Year\'s Day' =>               '2005-01-03',
        'Good Friday' =>                   '2005-03-25',
        'Easter Monday' =>                 '2005-03-28',
        'Victoria Day' =>                  '2005-05-23',
        'Canada Day' =>                    '2005-07-01',
        'Labour Day' =>                    '2005-09-05',
        'Thanksgiving Day' =>              '2005-10-10',
        'Remembrance Day' =>               '2005-11-11',
        'Christmas Day' =>                 '2005-12-26',
        'Boxing Day' =>                    '2005-12-27',
    },

    2006 => {
        'New Year\'s Day' =>               '2006-01-02',
        'Good Friday' =>                   '2006-04-14',
        'Easter Monday' =>                 '2006-04-17',
        'Victoria Day' =>                  '2006-05-22',
        'Canada Day' =>                    '2006-07-03',
        'Labour Day' =>                    '2006-09-04',
        'Thanksgiving Day' =>              '2006-10-09',
        'Remembrance Day' =>               '2006-11-13',
        'Christmas Day' =>                 '2006-12-25',
        'Boxing Day' =>                    '2006-12-26',
    },

    2007 => {
        'New Year\'s Day' =>               '2007-01-01',
        'Good Friday' =>                   '2007-04-06',
        'Easter Monday' =>                 '2007-04-09',
        'Victoria Day' =>                  '2007-05-21',
        'Canada Day' =>                    '2007-07-02',
        'Labour Day' =>                    '2007-09-03',
        'Thanksgiving Day' =>              '2007-10-08',
        'Remembrance Day' =>               '2007-11-12',
        'Christmas Day' =>                 '2007-12-25',
        'Boxing Day' =>                    '2007-12-26',
    },

    2037 => {
        'New Year\'s Day' =>               '2037-01-01',
        'Good Friday' =>                   '2037-04-03',
        'Easter Monday' =>                 '2037-04-06',
        'Victoria Day' =>                  '2037-05-18',
        'Canada Day' =>                    '2037-07-01',
        'Labour Day' =>                    '2037-09-07',
        'Thanksgiving Day' =>              '2037-10-12',
        'Remembrance Day' =>               '2037-11-11',
        'Christmas Day' =>                 '2037-12-25',
        'Boxing Day' =>                    '2037-12-28',
    },

    2038 => {
        'New Year\'s Day' =>               '2038-01-01',
        'Good Friday' =>                   '2038-04-23',
        'Easter Monday' =>                 '2038-04-26',
        'Victoria Day' =>                  '2038-05-24',
        'Canada Day' =>                    '2038-07-01',
        'Labour Day' =>                    '2038-09-06',
        'Thanksgiving Day' =>              '2038-10-11',
        'Remembrance Day' =>               '2038-11-11',
        'Christmas Day' =>                 '2038-12-27',
        'Boxing Day' =>                    '2038-12-28',
    },

    2039 => {
        'New Year\'s Day' =>               '2039-01-03',
        'Good Friday' =>                   '2039-04-08',
        'Easter Monday' =>                 '2039-04-11',
        'Victoria Day' =>                  '2039-05-23',
        'Canada Day' =>                    '2039-07-01',
        'Labour Day' =>                    '2039-09-05',
        'Thanksgiving Day' =>              '2039-10-10',
        'Remembrance Day' =>               '2039-11-11',
        'Christmas Day' =>                 '2039-12-26',
        'Boxing Day' =>                    '2039-12-27',
    },

    2298 => {
        'New Year\'s Day' =>               '2298-01-03',
        'Good Friday' =>                   '2298-04-01',
        'Easter Monday' =>                 '2298-04-04',
        'Victoria Day' =>                  '2298-05-23',
        'Canada Day' =>                    '2298-07-01',
        'Labour Day' =>                    '2298-09-05',
        'Thanksgiving Day' =>              '2298-10-10',
        'Remembrance Day' =>               '2298-11-11',
        'Christmas Day' =>                 '2298-12-26',
        'Boxing Day' =>                    '2298-12-27',
    },

    2299 => {
        'New Year\'s Day' =>               '2299-01-02',
        'Good Friday' =>                   '2299-04-14',
        'Easter Monday' =>                 '2299-04-17',
        'Victoria Day' =>                  '2299-05-22',
        'Canada Day' =>                    '2299-07-03',
        'Labour Day' =>                    '2299-09-04',
        'Thanksgiving Day' =>              '2299-10-09',
        'Remembrance Day' =>               '2299-11-13',
        'Christmas Day' =>                 '2299-12-25',
        'Boxing Day' =>                    '2299-12-26',
    },

};
