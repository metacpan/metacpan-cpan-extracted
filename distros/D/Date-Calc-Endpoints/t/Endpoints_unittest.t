use Test::More qw(no_plan);
use strict;
use warnings;
use Date::Calc qw(Today);
use Date::Calc::Endpoints;

my $dr = Date::Calc::Endpoints->new();

sub string_accessor_test {
    my ($accessor, $bogus, @legit) = @_;
    my $ans;
    my $set_method = "set_$accessor";
    my $get_method = "get_$accessor";
    foreach my $val (@legit) {
        $ans = $dr->$set_method($val);
        cmp_ok($ans,'==',1,"Set $accessor to $val");
        $ans = $dr->$get_method();
        cmp_ok($ans,'eq',$val,"Get $accessor $val");
    }
    $ans = $dr->$set_method($bogus);
    cmp_ok($ans,'==',0,"Cannot $set_method to $bogus");
}

sub numeric_accessor_test {
    my ($accessor, $bogus, @legit) = @_;
    my $ans;
    my $set_method = "set_$accessor";
    my $get_method = "get_$accessor";
    foreach my $val (@legit) {
        $ans = $dr->$set_method($val);
        cmp_ok($ans,'==',1,"Set $accessor to $val");
        $ans = $dr->$get_method();
        cmp_ok($ans,'==',$val,"Get $accessor $val");
    }
    $ans = $dr->$set_method($bogus);
    cmp_ok($ans,'==',0,"Cannot $set_method to $bogus");
}

sub map_test {
    my ($set_method,$get_method,$bogus,$hash) = @_;
    my $ans;
    foreach my $key (keys %$hash) {
        my $val  = $hash->{$key};
        $ans = $dr->$set_method($key);
        cmp_ok($ans,'==',1,"$set_method to $key");
        $ans = $dr->$get_method();
        cmp_ok($ans,'==',$val,"$get_method is $val");
    }
    $ans = $dr->$set_method($bogus);
    cmp_ok($ans,'==',0,"Cannot $set_method to $bogus");
}

my @types = qw(YEAR QUARTER MONTH WEEK DAY);
my $dows = {
               'MONDAY'    => 1,
               'TUESDAY'   => 2,
               'WEDNESDAY' => 3,
               'THURSDAY'  => 4,
               'FRIDAY'    => 5,
               'SATURDAY'  => 6,
               'SUNDAY'    => 7,
           };

string_accessor_test('type','bogus',@types);
map_test('set_start_day_of_week','get_start_day_of_week','bogus',$dows);
numeric_accessor_test('intervals','',(-5..5));
numeric_accessor_test('span','-2',(1..5));
numeric_accessor_test('start_month_of_year',0,(1..6));
numeric_accessor_test('start_month_of_year',13,(7..12));
numeric_accessor_test('start_day_of_month',0,(1..14));
numeric_accessor_test('start_day_of_month',29,(15..28));
numeric_accessor_test('sliding_window',2,(0..1));
string_accessor_test('direction','*',('+','-'));

my $ans;
my $temp_string;
my @temp_array;
my $temp_ref;
my $print_format = "%04d-%02d-%02d";

## A default date is set
@temp_array = $dr->get_today_date();
ok(@temp_array,"Today date defined");
cmp_ok(scalar(@temp_array),'==',3,"Correct number of args in today date");
$temp_string = sprintf($print_format,$dr->get_today_date);
my $today_string = sprintf($print_format,Today);
cmp_ok($temp_string,'eq',$today_string,"Today string correct");


## set_today_date / get_today_date
$ans = $dr->set_today_date(2020,1,27);
cmp_ok($ans,'==',1,"Set valid today date");
$temp_string = sprintf($print_format,$dr->get_today_date);
cmp_ok($temp_string,'eq','2020-01-27',"Returned correct date");

$ans = $dr->set_today_date(2020,0,27);
cmp_ok($ans,'==',0,"Cannot set invalid today date");


## _set_default_parameters / _set_passed_parameters
$dr->set_start_day_of_week('TUESDAY');
$dr->_set_default_parameters();
cmp_ok($dr->_get_start_dow_name,'eq','MONDAY',"Set default parameters");

$dr->_set_passed_parameters({span => 8, start_day_of_week => 'SATURDAY'});
cmp_ok($dr->get_span,'==',8,"Set passed parameter - span");
cmp_ok($dr->_get_start_dow_name,'eq','SATURDAY',"Set passed parameter - start day of week");


## _set_print_format / _get_print_format
$ans = $dr->_set_print_format("%04d-%02d-%02s");
cmp_ok($ans,'==',0,"Invalid print format rejected");
$ans = $dr->_set_print_format($print_format);
cmp_ok($ans,'==',1,"Set valid print format");
cmp_ok($dr->_get_print_format,'eq',$print_format,"Correct print format set");


## _delta_ymd
$dr->_set_passed_parameters({type => 'YEAR', span => 5});
$temp_string = join ":", $dr->_delta_ymd;
cmp_ok($temp_string,'eq','5:0:0',"Delta YMD");


## _delta_per_period
$dr->set_type('QUARTER');
$temp_string = join ":", $dr->_delta_per_period;
cmp_ok($temp_string,'eq','0:3:0',"Delta per period");


## _negate
@temp_array = Date::Calc::Endpoints::_negate(1,2,-3);
cmp_ok($temp_array[0],'==',-1,"Negate");
cmp_ok($temp_array[1],'==',-2,"Negate");
cmp_ok($temp_array[2],'==', 3,"Negate");


## _date_to_array
@temp_array = $dr->_date_to_array('2015-10-10');
$temp_string = sprintf($print_format,@temp_array);
cmp_ok($temp_string,'eq','2015-10-10',"Date to array - passed string");

@temp_array = $dr->_date_to_array(2010,5,14);
$temp_string = sprintf($print_format,@temp_array);
cmp_ok($temp_string,'eq','2010-05-14',"Date to array - passed array");


## _array_to_date
$temp_string = $dr->_array_to_date(2010,4,9);
cmp_ok($temp_string,'eq','2010-04-09',"Array to date");


## _add_delta_ymd
@temp_array = $dr->_add_delta_ymd(2010,1,1,2,3,4);
$temp_string = sprintf($print_format,@temp_array);
cmp_ok($temp_string,'eq','2012-04-05',"Add delta YMD");

@temp_array = $dr->_add_delta_ymd(2010,1,1,-3000,3,4);
cmp_ok(scalar(@temp_array),'==',0,"Add delta YMD invalid");


## _start_reference
$dr->set_type('MONTH');
$dr->set_today_date('2014-04-17');
@temp_array = $dr->_start_reference;
$temp_string = sprintf($print_format,@temp_array);
cmp_ok($temp_string,'eq','2014-04-01',"Set start reference");


## _get_start_date / _get_end_date / _get_last_date
$dr->_set_default_parameters;
$dr->set_today_date('2014-04-17');
@temp_array = $dr->_get_start_date;
$temp_string = sprintf($print_format,@temp_array);
cmp_ok($temp_string,'eq','2014-03-01',"Get start date");

@temp_array = $dr->_get_end_date(@temp_array);
$temp_string = sprintf($print_format,@temp_array);
cmp_ok($temp_string,'eq','2014-04-01',"Get start date");

@temp_array = $dr->_get_last_date(@temp_array);
$temp_string = sprintf($print_format,@temp_array);
cmp_ok($temp_string,'eq','2014-03-31',"Get start date");


## clear_error / set_error / get_error
$dr->clear_error;
$temp_ref = $dr->get_error;
cmp_ok(scalar(@$temp_ref),'==',0,"Cleared errors");

$dr->set_error("Setting error");
$temp_ref = $dr->get_error;
cmp_ok($temp_ref->[0],'eq','Setting error',"Set/get errors");


