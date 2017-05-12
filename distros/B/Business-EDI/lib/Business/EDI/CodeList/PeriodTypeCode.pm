package Business::EDI::CodeList::PeriodTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {2151;}
my $usage       = 'C';

# 2151  Period type code                                        [C]
# Desc: Code specifying the type of period.
# Repr: an..3

my %code_hash = (
'3M' => [ 'Quarter',
    'A subdivision of a year into four equal parts.' ],
'6M' => [ 'Half-year',
    'A subdivision of a year into two equal parts.' ],
'AA' => [ 'Air hour',
    'Flight duration irrespective of time zones.' ],
'AD' => [ 'Air day',
    'Flight duration irrespective of time zones.' ],
'CD' => [ 'Calendar day (includes weekends and holidays)',
    'Period given as a number of days including weekends and holidays.' ],
'CW' => [ 'Calendar week (7day)',
    'Period given as a number of 7day-weeks including holidays.' ],
'D' => [ 'Day',
    'The twenty-four hour period during which the earth completes one rotation on its axis.' ],
'DC' => [ 'Ten days period',
    'Period of 10 days.' ],
'F' => [ 'Period of two weeks',
    'A period of time lasting fourteen days. Synonym: Fortnight.' ],
'H' => [ 'Hour',
    'One of the twenty-four sub-divisions of a day.' ],
'HM' => [ 'Half month',
    'A subdivision of a month into two equal parts.' ],
'M' => [ 'Month',
    'One of twelve divisions of the year as determined by the Gregorian calendar.' ],
'MN' => [ 'Minute',
    'A unit of time equal to 1/60 of an hour, or 60 seconds.' ],
'P' => [ 'Four month period',
    'A period of time, measured in monthly increments, consisting of four sequential months.' ],
'S' => [ 'Second',
    'A unit of time equal to 1/60 of a minute.' ],
'SD' => [ 'Surface day',
    'The voyage duration irrespective of time zones.' ],
'SI' => [ 'Indefinite',
    'An indefinite period.' ],
'W' => [ 'Week',
    'Period of seven days.' ],
'WD' => [ 'Workday',
    'Day on which work is usually done.' ],
'WW' => [ '5 day work week',
    'Monday through Friday.' ],
'Y' => [ 'Year',
    'The period of time as measured by the Gregorian calendar in which the earth completes a single revolution around the sun.' ],
'ZZZ' => [ 'Mutually defined',
    'Period as per agreement.' ],
);
sub get_codes { return \%code_hash; }

1;
