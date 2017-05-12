use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;

BEGIN { use_ok('Date::Holidays::CA', qw(:all)) };



INSTANTIATION: {
    my $calendar = Date::Holidays::CA->new();
    isa_ok($calendar, 'Date::Holidays::CA');
}

DEFAULTS: {
    my $calendar = Date::Holidays::CA->new();
    is($calendar->get('province'), 'CA',    
        'Default province set to CA'
    );
    is($calendar->get('language'), 'EN/FR', 
        'Default language set to EN/FR'
    );
}

CASE_INSENSITIVITY: {
    my $ON_calendar = Date::Holidays::CA->new(
        {province => 'ON', language => 'EN'}
    );
    
    my $on_calendar = Date::Holidays::CA->new(
        {province => 'on', language => 'en'}
    );
    
    is_deeply(
        $ON_calendar, $on_calendar, 
        'Province and language names are case-insensitive'
    );
}




# test usage of each function -- both object-oriented and procedural.
# the results must be the same!
# is_holiday and is_ca_holiday must return the exact same thing;
# same for holidays and ca_holidays
# as well, the results of the foo_dt types must be datetime objects,
# and their contents must match the results of the `standard' fn calls

# foreach fn
#   call it, call its alias, call the _dt version

# REMEMBER!  the IS_HOLIDAY family of fns returns the HOLIDAY NAME
#            as its 'true' value!
#    is_holiday
#    is_ca_holiday
#    is_holiday_dt
#
#    holidays
#    ca_holidays
#    holidays_dt
#
# IS_HOLIDAY: {
# }
