package TestData;
use warnings;
use strict;

###########################################################################
# name: TestData.pm
# desc: Preprocessed variables for tests
###########################################################################

use vars qw(
    $VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK
    @datetest @diffs
    %hash01 %hash02 %hash03 %hash04 %hash05 %hash06 %hash07 %hash08 %hash09 %hash10 %hash11 %hash12 %hash13
    %tests %expected02 %expected03 %setargs
    %exts %monthtest %daytest
    @monthlists
    @format01 @format02 @format03
    $on_unix
);

$VERSION = '0.27';

require Exporter;

@ISA = qw(Exporter);

%EXPORT_TAGS = ( 'all' => [ qw(
    @datetest @diffs
    %hash07
    %tests %expected02 %expected03 %setargs
    %exts %monthtest %daytest
    @monthlists
    @format01 @format02 @format03
    $on_unix
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT    = ( @{ $EXPORT_TAGS{'all'} } );

# -------------------------------------------------------------------------
# Variables

my %os = (MacOS   => 0,
          MSWin32 => 0,
          os2     => 0,
          VMS     => 0,
          epoc    => 0);

$on_unix = (exists $os{$^O} ? 0 : 1);

@datetest = (
    { array => [24,3,1976,3],   dotw => 3, tl => 1 },
    { array => [13,9,1965,1],   dotw => 1, tl => 2 },
    { array => [3,11,2000,5],   dotw => 5, tl => 1 },
    { array => [25,5,2003,0],   dotw => 0, tl => 1 },
    { array => [1,1,1900,1],    dotw => 1, tl => 0 },
    { array => [5,7,2056,3],    dotw => 3, tl => 0 },

    { array => [0,9,1965,1],    dotw => 1, tl => 0, invalid => 1 },
    { array => [13,0,1965,1],   dotw => 1, tl => 0, invalid => 1 },
    { array => [13,9,0,1],      dotw => 1, tl => 0, invalid => 1 },
);

@diffs = (
    { from => [],          to => [],          compare =>  0, tl => 1 },
    { from => [],          to => [24,3,1976], compare => -1, tl => 1 },
    { from => [24,3,1976], to => [],          compare =>  1, tl => 1 },

    { from => [0,0,0],     to => [0,0,0],     compare =>  0, tl => 1 },
    { from => [0,0,0],     to => [24,3,1976], compare => -1, tl => 1 },
    { from => [24,3,1976], to => [0,0,0],     compare =>  1, tl => 1 },

    { from => [24,3,1976], to => [24,3,1976], compare =>  0, tl => 1 },
    { from => [24,3,1976], to => [13,9,1965], compare =>  1, tl => 2 },
    { from => [24,3,1976], to => [3,11,2000], compare => -1, tl => 1 },
    { from => [24,3,1976], to => [25,5,2003], compare => -1, tl => 1 },
    { from => [24,3,1976], to => [1,1,1900],  compare =>  1, tl => 0 },
    { from => [24,3,1976], to => [5,7,2056],  compare => -1, tl => 0 },
    { from => [1,3,1976],  to => [1,4,1976],  compare => -1, tl => 1 },
    { from => [10,5,2003], to => [11,5,2003], compare => -1, tl => 1 },
);


%hash01 = (
    'options'   => 10,
    'exclude'   => { 'weekend' => 1 },
    'start'     => '01-05-2003',
);

%hash02 = (
    'exclude'   => { 'weekday' => 1 },
    'start'     => '01-05-2003',
    'end'       => '10-05-2003',
    'name'      => 'TestTest',
    'select'    => '04-05-2003',
);

%hash03 = (
    'options'   => 10,
    'exclude'   => { 'monday' => 1, 'tuesday' => 1, 'wednesday' => 1 },
    'start'     => '01-05-2003',
    'end'       => '25-05-2003',
);

%hash04 = (
    'start'     => '13-09-1965',
    'end'       => '13-09-1965',
    'name'      => 'TestTest',
    'select'    => '13-09-1965',
);

%hash05 = (
    'start'     => '01-12-2014',
    'end'       => '07-01-2015',
    'name'      => 'TestTest',
    'select'    => '03-01-2015',
    'exclude'   => { 'monday' => 1, 'tuesday' => 1, 'thursday' => 1, 'friday' => 1, 'sunday' => 1 },
);

%hash06 = (
    'start'     => '30-11-2014',
    'end'       => '01-01-2015',
    'name'      => 'TestTest',
    'exclude'   => { 'december' => 1 },
);

%hash07 = (
    'start'     => '30-11-2014',
    'options'   => 0
);

%hash08 = (
    'start'     => '30-11-2014',
    'end'       => '01-01-2014',
);

%hash09 = (
    'end'       => '01-01-2014',
    'start'     => '',
);

%hash10 = (
    'exclude'   => { 'blah' => 1 },
    'start'     => '01-05-2003',
    'end'       => '10-05-2003',
);

%hash11 = (
    'start'     => '01-05-2003',
    'end'       => '10-05-2003',
    'blah'      => 1
);

%hash12 = (
    'exclude'   => { 'weekday' => 1, 'weekend' => 1 },
    'start'     => '01-05-2003',
    'end'       => '10-05-2003',
);

%hash13 = (
    'exclude'   => { 'january' => 1, 'february' => 1, 'march' => 1, 'april' => 1, 'may' => 1, 'june' => 1, 'july' => 1, 'august' => 1, 'september' => 1, 'october' => 1, 'november' => 1, 'december' => 1 },
    'start'     => '01-05-2003',
    'end'       => '10-05-2003',
);

%setargs = (
    1 => { hash => \%hash01, result => 0 },
    2 => { hash => \%hash02, result => 0 },
    3 => { hash => \%hash03, result => 0 },
    4 => { hash => \%hash04, result => 0 },
    5 => { hash => \%hash05, result => 0 },
    6 => { hash => \%hash06, result => 0 },
    7 => { hash => \%hash07, result => 1 },
    8 => { hash => \%hash08, result => 1 },
    9 => { hash => \%hash09, result => 1 },
   10 => { hash => \%hash10, result => 0 },
   11 => { hash => \%hash11, result => 0 },
   12 => { hash => \%hash12, result => 1 },
   13 => { hash => \%hash13, result => 1 },
);

%tests = (
    1  => { f1 => 'YYYY-MM-DD',     f2 => undef,                    hash => undef    },
    2  => { f1 => 'DD-MM-YYYY',     f2 => undef,                    hash => \%hash01 },
    3  => { f1 => 'MM-DD-YYYY',     f2 => undef,                    hash => \%hash02 },
    4  => { f1 => 'DD-MONTH-YYYY',  f2 => undef,                    hash => \%hash03 },
    5  => { f1 => 'YYYY-MM-DD',     f2 => 'DD-MM-YYYY',             hash => undef    },
    6  => { f1 => 'DD-MM-YYYY',     f2 => 'YYYY-MM-DD',             hash => \%hash01 },
    7  => { f1 => 'MM-DD-YYYY',     f2 => 'DD MONTH, YYYY',         hash => \%hash02 },
    8  => { f1 => 'DD-MONTH-YYYY',  f2 => 'DAY DDEXT MONTH, YYYY',  hash => \%hash03 },
    9  => { f1 => undef,            f2 => undef,                    hash => undef    },
    10 => { f1 => undef,            f2 => undef,                    hash => \%hash03 },
    11 => { f1 => 'DD-MONTH-YYYY',  f2 => undef,                    hash => \%hash04 },
    12 => { f1 => 'YYYY-MM-DD',     f2 => 'DD-MONTH-YYYY',          hash => \%hash04 },
    13 => { f1 => undef,            f2 => undef,                    hash => \%hash04 },
    14 => { f1 => 'YYYY-MM-DD',     f2 => 'DD-MM-YYYY',             hash => \%hash05 },
    15 => { f1 => 'YYYY-MM-DD',     f2 => 'DD-MM-YYYY',             hash => \%hash06 },
);

%expected02 = (
1 => [
          '2003-05-24',
          '2003-05-25',
          '2003-05-26',
          '2003-05-27',
          '2003-05-28',
          '2003-05-29',
          '2003-05-30',
          '2003-05-31',
          '2003-06-01',
          '2003-06-02',
          '2003-06-03',
          '2003-06-04',
          '2003-06-05',
          '2003-06-06',
          '2003-06-07',
          '2003-06-08',
          '2003-06-09',
          '2003-06-10',
          '2003-06-11',
          '2003-06-12',
          '2003-06-13',
          '2003-06-14',
          '2003-06-15',
          '2003-06-16',
          '2003-06-17',
          '2003-06-18',
          '2003-06-19',
          '2003-06-20',
          '2003-06-21',
          '2003-06-22'
        ],
2 => [
          '01-05-2003',
          '02-05-2003',
          '05-05-2003',
          '06-05-2003',
          '07-05-2003',
          '08-05-2003',
          '09-05-2003',
          '12-05-2003',
          '13-05-2003',
          '14-05-2003'
        ],
3 => [
          '05-03-2003',
          '05-04-2003',
          '05-10-2003'
        ],
4 => [
          '01-May-2003',
          '02-May-2003',
          '03-May-2003',
          '04-May-2003',
          '08-May-2003',
          '09-May-2003',
          '10-May-2003',
          '11-May-2003',
          '15-May-2003',
          '16-May-2003'
        ],
5 => {
          '2003-06-01' => '01-06-2003',
          '2003-06-10' => '10-06-2003',
          '2003-06-02' => '02-06-2003',
          '2003-05-30' => '30-05-2003',
          '2003-06-11' => '11-06-2003',
          '2003-06-03' => '03-06-2003',
          '2003-05-31' => '31-05-2003',
          '2003-06-20' => '20-06-2003',
          '2003-06-12' => '12-06-2003',
          '2003-06-04' => '04-06-2003',
          '2003-05-24' => '24-05-2003',
          '2003-06-21' => '21-06-2003',
          '2003-06-13' => '13-06-2003',
          '2003-06-05' => '05-06-2003',
          '2003-05-25' => '25-05-2003',
          '2003-06-22' => '22-06-2003',
          '2003-06-14' => '14-06-2003',
          '2003-06-06' => '06-06-2003',
          '2003-05-26' => '26-05-2003',
          '2003-06-15' => '15-06-2003',
          '2003-06-07' => '07-06-2003',
          '2003-05-27' => '27-05-2003',
          '2003-06-16' => '16-06-2003',
          '2003-06-08' => '08-06-2003',
          '2003-05-28' => '28-05-2003',
          '2003-06-17' => '17-06-2003',
          '2003-06-09' => '09-06-2003',
          '2003-05-29' => '29-05-2003',
          '2003-06-18' => '18-06-2003',
          '2003-06-19' => '19-06-2003'
        },
6 => {
          '07-05-2003' => '2003-05-07',
          '09-05-2003' => '2003-05-09',
          '02-05-2003' => '2003-05-02',
          '13-05-2003' => '2003-05-13',
          '06-05-2003' => '2003-05-06',
          '08-05-2003' => '2003-05-08',
          '01-05-2003' => '2003-05-01',
          '12-05-2003' => '2003-05-12',
          '05-05-2003' => '2003-05-05',
          '14-05-2003' => '2003-05-14'
        },
7 => {
          '05-04-2003' => '04 May, 2003',
          '05-03-2003' => '03 May, 2003',
          '05-10-2003' => '10 May, 2003'
        },
8 => {
          '01-May-2003' => 'Thursday 1st May, 2003',
          '02-May-2003' => 'Friday 2nd May, 2003',
          '03-May-2003' => 'Saturday 3rd May, 2003',
          '04-May-2003' => 'Sunday 4th May, 2003',
          '08-May-2003' => 'Thursday 8th May, 2003',
          '09-May-2003' => 'Friday 9th May, 2003',
          '10-May-2003' => 'Saturday 10th May, 2003',
          '11-May-2003' => 'Sunday 11th May, 2003',
          '15-May-2003' => 'Thursday 15th May, 2003',
          '16-May-2003' => 'Friday 16th May, 2003'
        },
9 => [
          '24-05-2003',
          '25-05-2003',
          '26-05-2003',
          '27-05-2003',
          '28-05-2003',
          '29-05-2003',
          '30-05-2003',
          '31-05-2003',
          '01-06-2003',
          '02-06-2003',
          '03-06-2003',
          '04-06-2003',
          '05-06-2003',
          '06-06-2003',
          '07-06-2003',
          '08-06-2003',
          '09-06-2003',
          '10-06-2003',
          '11-06-2003',
          '12-06-2003',
          '13-06-2003',
          '14-06-2003',
          '15-06-2003',
          '16-06-2003',
          '17-06-2003',
          '18-06-2003',
          '19-06-2003',
          '20-06-2003',
          '21-06-2003',
          '22-06-2003'
        ],
10 => [
          '01-05-2003',
          '02-05-2003',
          '03-05-2003',
          '04-05-2003',
          '08-05-2003',
          '09-05-2003',
          '10-05-2003',
          '11-05-2003',
          '15-05-2003',
          '16-05-2003'
        ],
11 => [
          '13-September-1965',
        ],
12 => {
          '1965-09-13' => '13-September-1965',
        },
13 => [
          '13-09-1965',
        ],
14 => [
        '2014-12-03' => '03-12-2014',
        '2014-12-06' => '06-12-2014',
        '2014-12-10' => '10-12-2014',
        '2014-12-13' => '13-12-2014',
        '2014-12-17' => '17-12-2014',
        '2014-12-20' => '20-12-2014',
        '2014-12-24' => '24-12-2014',
        '2014-12-27' => '27-12-2014',
        '2014-12-31' => '31-12-2014',
        '2015-01-03' => '03-01-2015',
        '2015-01-07' => '07-01-2015',
        ],
15 => [
        '2014-11-30' => '30-11-2014',
        '2015-01-01' => '01-01-2015',
        ],
);

%expected03 = (
1 =>
q|<select name='calendar'>
<option value='2003-05-24'>2003-05-24</option>
<option value='2003-05-25'>2003-05-25</option>
<option value='2003-05-26'>2003-05-26</option>
<option value='2003-05-27'>2003-05-27</option>
<option value='2003-05-28'>2003-05-28</option>
<option value='2003-05-29'>2003-05-29</option>
<option value='2003-05-30'>2003-05-30</option>
<option value='2003-05-31'>2003-05-31</option>
<option value='2003-06-01'>2003-06-01</option>
<option value='2003-06-02'>2003-06-02</option>
<option value='2003-06-03'>2003-06-03</option>
<option value='2003-06-04'>2003-06-04</option>
<option value='2003-06-05'>2003-06-05</option>
<option value='2003-06-06'>2003-06-06</option>
<option value='2003-06-07'>2003-06-07</option>
<option value='2003-06-08'>2003-06-08</option>
<option value='2003-06-09'>2003-06-09</option>
<option value='2003-06-10'>2003-06-10</option>
<option value='2003-06-11'>2003-06-11</option>
<option value='2003-06-12'>2003-06-12</option>
<option value='2003-06-13'>2003-06-13</option>
<option value='2003-06-14'>2003-06-14</option>
<option value='2003-06-15'>2003-06-15</option>
<option value='2003-06-16'>2003-06-16</option>
<option value='2003-06-17'>2003-06-17</option>
<option value='2003-06-18'>2003-06-18</option>
<option value='2003-06-19'>2003-06-19</option>
<option value='2003-06-20'>2003-06-20</option>
<option value='2003-06-21'>2003-06-21</option>
<option value='2003-06-22'>2003-06-22</option>
</select>
|,
2 =>
q|<select name='calendar'>
<option value='01-05-2003'>01-05-2003</option>
<option value='02-05-2003'>02-05-2003</option>
<option value='05-05-2003'>05-05-2003</option>
<option value='06-05-2003'>06-05-2003</option>
<option value='07-05-2003'>07-05-2003</option>
<option value='08-05-2003'>08-05-2003</option>
<option value='09-05-2003'>09-05-2003</option>
<option value='12-05-2003'>12-05-2003</option>
<option value='13-05-2003'>13-05-2003</option>
<option value='14-05-2003'>14-05-2003</option>
</select>
|,
3 =>
q|<select name='TestTest'>
<option value='05-03-2003'>05-03-2003</option>
<option value='05-04-2003' selected="selected">05-04-2003</option>
<option value='05-10-2003'>05-10-2003</option>
</select>
|,
4 =>
q|<select name='calendar'>
<option value='01-May-2003'>01-May-2003</option>
<option value='02-May-2003'>02-May-2003</option>
<option value='03-May-2003'>03-May-2003</option>
<option value='04-May-2003'>04-May-2003</option>
<option value='08-May-2003'>08-May-2003</option>
<option value='09-May-2003'>09-May-2003</option>
<option value='10-May-2003'>10-May-2003</option>
<option value='11-May-2003'>11-May-2003</option>
<option value='15-May-2003'>15-May-2003</option>
<option value='16-May-2003'>16-May-2003</option>
</select>
|,
5 =>
q|<select name='calendar'>
<option value='2003-05-24'>24-05-2003</option>
<option value='2003-05-25'>25-05-2003</option>
<option value='2003-05-26'>26-05-2003</option>
<option value='2003-05-27'>27-05-2003</option>
<option value='2003-05-28'>28-05-2003</option>
<option value='2003-05-29'>29-05-2003</option>
<option value='2003-05-30'>30-05-2003</option>
<option value='2003-05-31'>31-05-2003</option>
<option value='2003-06-01'>01-06-2003</option>
<option value='2003-06-02'>02-06-2003</option>
<option value='2003-06-03'>03-06-2003</option>
<option value='2003-06-04'>04-06-2003</option>
<option value='2003-06-05'>05-06-2003</option>
<option value='2003-06-06'>06-06-2003</option>
<option value='2003-06-07'>07-06-2003</option>
<option value='2003-06-08'>08-06-2003</option>
<option value='2003-06-09'>09-06-2003</option>
<option value='2003-06-10'>10-06-2003</option>
<option value='2003-06-11'>11-06-2003</option>
<option value='2003-06-12'>12-06-2003</option>
<option value='2003-06-13'>13-06-2003</option>
<option value='2003-06-14'>14-06-2003</option>
<option value='2003-06-15'>15-06-2003</option>
<option value='2003-06-16'>16-06-2003</option>
<option value='2003-06-17'>17-06-2003</option>
<option value='2003-06-18'>18-06-2003</option>
<option value='2003-06-19'>19-06-2003</option>
<option value='2003-06-20'>20-06-2003</option>
<option value='2003-06-21'>21-06-2003</option>
<option value='2003-06-22'>22-06-2003</option>
</select>
|,
6 =>
q|<select name='calendar'>
<option value='01-05-2003'>2003-05-01</option>
<option value='02-05-2003'>2003-05-02</option>
<option value='05-05-2003'>2003-05-05</option>
<option value='06-05-2003'>2003-05-06</option>
<option value='07-05-2003'>2003-05-07</option>
<option value='08-05-2003'>2003-05-08</option>
<option value='09-05-2003'>2003-05-09</option>
<option value='12-05-2003'>2003-05-12</option>
<option value='13-05-2003'>2003-05-13</option>
<option value='14-05-2003'>2003-05-14</option>
</select>
|,
7 =>
q|<select name='TestTest'>
<option value='05-03-2003'>03 May, 2003</option>
<option value='05-04-2003' selected="selected">04 May, 2003</option>
<option value='05-10-2003'>10 May, 2003</option>
</select>
|,
8 =>
q|<select name='calendar'>
<option value='01-May-2003'>Thursday 1st May, 2003</option>
<option value='02-May-2003'>Friday 2nd May, 2003</option>
<option value='03-May-2003'>Saturday 3rd May, 2003</option>
<option value='04-May-2003'>Sunday 4th May, 2003</option>
<option value='08-May-2003'>Thursday 8th May, 2003</option>
<option value='09-May-2003'>Friday 9th May, 2003</option>
<option value='10-May-2003'>Saturday 10th May, 2003</option>
<option value='11-May-2003'>Sunday 11th May, 2003</option>
<option value='15-May-2003'>Thursday 15th May, 2003</option>
<option value='16-May-2003'>Friday 16th May, 2003</option>
</select>
|,
9 =>
q|<select name='calendar'>
<option value='24-05-2003'>24-05-2003</option>
<option value='25-05-2003'>25-05-2003</option>
<option value='26-05-2003'>26-05-2003</option>
<option value='27-05-2003'>27-05-2003</option>
<option value='28-05-2003'>28-05-2003</option>
<option value='29-05-2003'>29-05-2003</option>
<option value='30-05-2003'>30-05-2003</option>
<option value='31-05-2003'>31-05-2003</option>
<option value='01-06-2003'>01-06-2003</option>
<option value='02-06-2003'>02-06-2003</option>
<option value='03-06-2003'>03-06-2003</option>
<option value='04-06-2003'>04-06-2003</option>
<option value='05-06-2003'>05-06-2003</option>
<option value='06-06-2003'>06-06-2003</option>
<option value='07-06-2003'>07-06-2003</option>
<option value='08-06-2003'>08-06-2003</option>
<option value='09-06-2003'>09-06-2003</option>
<option value='10-06-2003'>10-06-2003</option>
<option value='11-06-2003'>11-06-2003</option>
<option value='12-06-2003'>12-06-2003</option>
<option value='13-06-2003'>13-06-2003</option>
<option value='14-06-2003'>14-06-2003</option>
<option value='15-06-2003'>15-06-2003</option>
<option value='16-06-2003'>16-06-2003</option>
<option value='17-06-2003'>17-06-2003</option>
<option value='18-06-2003'>18-06-2003</option>
<option value='19-06-2003'>19-06-2003</option>
<option value='20-06-2003'>20-06-2003</option>
<option value='21-06-2003'>21-06-2003</option>
<option value='22-06-2003'>22-06-2003</option>
</select>
|,
10 =>
q|<select name='calendar'>
<option value='01-05-2003'>01-05-2003</option>
<option value='02-05-2003'>02-05-2003</option>
<option value='03-05-2003'>03-05-2003</option>
<option value='04-05-2003'>04-05-2003</option>
<option value='08-05-2003'>08-05-2003</option>
<option value='09-05-2003'>09-05-2003</option>
<option value='10-05-2003'>10-05-2003</option>
<option value='11-05-2003'>11-05-2003</option>
<option value='15-05-2003'>15-05-2003</option>
<option value='16-05-2003'>16-05-2003</option>
</select>
|,
11 =>
q|<select name='TestTest'>
<option value='13-September-1965' selected="selected">13-September-1965</option>
</select>
|,
12 =>
q|<select name='TestTest'>
<option value='1965-09-13' selected="selected">13-September-1965</option>
</select>
|,
13 =>
q|<select name='TestTest'>
<option value='13-09-1965' selected="selected">13-09-1965</option>
</select>
|,
14 =>
q|<select name='TestTest'>
<option value='2014-12-03'>03-12-2014</option>
<option value='2014-12-06'>06-12-2014</option>
<option value='2014-12-10'>10-12-2014</option>
<option value='2014-12-13'>13-12-2014</option>
<option value='2014-12-17'>17-12-2014</option>
<option value='2014-12-20'>20-12-2014</option>
<option value='2014-12-24'>24-12-2014</option>
<option value='2014-12-27'>27-12-2014</option>
<option value='2014-12-31'>31-12-2014</option>
<option value='2015-01-03' selected="selected">03-01-2015</option>
<option value='2015-01-07'>07-01-2015</option>
</select>
|,
15 =>
q|<select name='TestTest'>
<option value='2014-11-30'>30-11-2014</option>
<option value='2015-01-01'>01-01-2015</option>
</select>
|,
);

%exts = (
1 => 'st',
2 => 'nd',
3 => 'rd',
4 => 'th',
5 => 'th',
6 => 'th',
7 => 'th',
8 => 'th',
9 => 'th',
10 => 'th',
11 => 'th',
12 => 'th',
13 => 'th',
14 => 'th',
15 => 'th',
16 => 'th',
17 => 'th',
18 => 'th',
19 => 'th',
20 => 'th',
21 => 'st',
22 => 'nd',
23 => 'rd',
24 => 'th',
25 => 'th',
26 => 'th',
27 => 'th',
28 => 'th',
29 => 'th',
30 => 'th',
31 => 'st',
);

%monthtest = (
1 => 'January',
2 => 'February',
3 => 'March',
4 => 'April',
5 => 'May',
6 => 'June',
7 => 'July',
8 => 'August',
9 => 'September',
10 => 'October',
11 => 'November',
12 => 'December',
'January' => 1,
'February' => 2,
'March' => 3,
'April' => 4,
'May' => 5,
'June' => 6,
'July' => 7,
'August' => 8,
'September' => 9,
'October' => 10,
'November' => 11,
'December' => 12,
);

%daytest = (
0 => 'Sunday',
1 => 'Monday',
2 => 'Tuesday',
3 => 'Wednesday',
4 => 'Thursday',
5 => 'Friday',
6 => 'Saturday',
'Sunday' => 0,
'Monday' => 1,
'Tuesday' => 2,
'Wednesday' => 3,
'Thursday' => 4,
'Friday' => 5,
'Saturday' => 6,
);

@monthlists = (
{ array => [9,1965], hash => {
    1 => 3, 2 => 4, 3 => 5, 4 => 6, 5 => 0, 6 => 1, 7 => 2,
    8 => 3, 9 => 4, 10 => 5, 11 => 6, 12 => 0, 13 => 1, 14 => 2,
    15 => 3, 16 => 4, 17 => 5, 18 => 6, 19 => 0, 20 => 1, 21 => 2,
    22 => 3, 23 => 4, 24 => 5, 25 => 6, 26 => 0, 27 => 1, 28 => 2,
    29 => 3, 30 => 4,
} },
{ array => [3,1976], hash => {
    1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6, 7 => 0,
    8 => 1, 9 => 2, 10 => 3, 11 => 4, 12 => 5, 13 => 6, 14 => 0,
    15 => 1, 16 => 2, 17 => 3, 18 => 4, 19 => 5, 20 => 6, 21 => 0,
    22 => 1, 23 => 2, 24 => 3, 25 => 4, 26 => 5, 27 => 6, 28 => 0,
    29 => 1, 30 => 2, 31 => 3,
} },
{ array => [2,2000], hash => {
    1 => 2, 2 => 3, 3 => 4, 4 => 5, 5 => 6, 6 => 0, 7 => 1,
    8 => 2, 9 => 3, 10 => 4, 11 => 5, 12 => 6, 13 => 0, 14 => 1,
    15 => 2, 16 => 3, 17 => 4, 18 => 5, 19 => 6, 20 => 0, 21 => 1,
    22 => 2, 23 => 3, 24 => 4, 25 => 5, 26 => 6, 27 => 0, 28 => 1,
    29 => 2,
} },
{ array => [2,1999], hash => {
    1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6, 7 => 0,
    8 => 1, 9 => 2, 10 => 3, 11 => 4, 12 => 5, 13 => 6, 14 => 0,
    15 => 1, 16 => 2, 17 => 3, 18 => 4, 19 => 5, 20 => 6, 21 => 0,
    22 => 1, 23 => 2, 24 => 3, 25 => 4, 26 => 5, 27 => 6, 28 => 0,
} },
);

@format01 = (
    {   array => [ 'YYYY-MM-DD', 0,9,1965 ],
        result => undef },
    {   array => [ 'YYYY-MM-DD', 13,0,1965 ],
        result => undef },
    {   array => [ 'YYYY-MM-DD', 13,9,0 ],
        result => undef },

    {   array => [ 'YYYY-MM-DD', 13,9,1965 ],
        result => '1965-09-13' },
    {   array => [ 'DAY, DDEXT MONTH YYYY', 13,9,1965,1 ],
        result => 'Monday, 13th September 1965' },
    {   array => [ 'DMY', 13,9,1965 ],
        result => '13-09-1965' },
    {   array => [ 'MDY', 13,9,1965 ],
        result => '09-13-1965' },
    {   array => [ 'YMD', 13,9,1965 ],
        result => '1965-09-13' },
    {   array => [ 'DABV, DD MABV YYYY', 13,9,1965,1 ],
        result => 'Mon, 13 Sep 1965' },
#   {   array => [ 'EPOCH', 13,9,1965 ],
#       result => '9999' },
);

@format02 = (
    {   array => [ '1965-09-00', 'YYYY-MM-DD', 'DAY, DDEXT MONTH YYYY' ],
        result => '1965-09-00' },
    {   array => [ '1965-00-13', 'YYYY-MM-DD', 'DAY, DDEXT MONTH YYYY' ],
        result => '1965-00-13' },
    {   array => [ '0000-09-13', 'YYYY-MM-DD', 'DAY, DDEXT MONTH YYYY' ],
        result => '0000-09-13' },

    {   array => [ '1965-09-13', 'YYYY-MM-DD', 'DAY, DDEXT MONTH YYYY' ],
        result => 'Monday, 13th September 1965' },
    {   array => [ 'Monday, 13th September 1965', 'DAY, DDEXT MONTH YYYY', 'YYYY-MM-DD' ],
        result => '1965-09-13' },
    {   array => [ '1965-09-13', 'YYYY-MM-DD', 'DDEXT MONTH YYYY' ],
        result => '13th September 1965' },

    {   array => [ 'Tuesday, 3rd November 2015', 'DAY, DDEXT MONTH YYYY', 'YYYY-MM-DD' ],
        result => '2015-11-03' },
    {   array => [ 'Wednesday, 8th February 2015', 'DAY, DDEXT MONTH YYYY', 'DDEXT MONTH YYYY, DAY' ],
        result => '8th February 2015, Wednesday' },

);

@format03 = (
    {   array => [ 'EPOCH', 13,9,1965 ],
        result => '-1' },
    {   array => [ 'EPOCH', 24,3,1976 ],
        result => '196516800' },
    {   array => [ 'EPOCH', 3,11,2000 ],
        result => '973252800' },
    {   array => [ 'EPOCH', 1,1,1970 ],
        result => '43200' },
    {   array => [ 'EPOCH', 1,1,1900 ],
        result => '-1' },
    {   array => [ 'EPOCH', 5,7,2056 ],
        result => '-1' },
    {   array => [ 'EPOCH', 1,1,2038 ],
        result => '-1' },
);

__END__

=head1 NAME

t/TestData.pm - test variables module.

=head1 AUTHOR

  Barbie, E<lt>barbie@cpan.orgE<gt>
  for Miss Barbell Productions L<http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2003-2012 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
