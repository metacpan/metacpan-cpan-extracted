use Test::More qw(no_plan);
use strict;
use warnings;

require_ok('Date::Calc::Endpoints');
require_ok('Class::Accessor');
require_ok('Date::Calc');

can_ok('Date::Calc::Endpoints', qw(new get_dates set_type get_type set_intervals 
        get_intervals set_span get_span set_start_day_of_week get_start_day_of_week 
        set_today_date get_today_date set_sliding_window get_sliding_window 
        set_direction get_direction set_error get_error clear_error 
        _set_default_parameters _set_passed_parameters _get_start_date 
        _get_end_date _get_last_date _start_reference _set_start_dow_name 
        _get_start_dow_name _set_print_format _get_print_format _delta_ymd 
        _delta_per_period _date_to_array _array_to_date _add_delta_ymd 
        ));

