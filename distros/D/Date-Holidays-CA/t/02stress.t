use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;

BEGIN { use_ok('Date::Holidays::CA', qw(:all)) };

# break stuff here.
# if we feed any of the functions nonsensical data, will they barf?


GET_NO_FIELD: {
    my $calendar = Date::Holidays::CA->new();
    dies_ok { $calendar->get(); } 'must specify which field to get()';
}

GET_NONEXISTENT_FIELD: {
    my $calendar = Date::Holidays::CA->new();
    dies_ok { 
        $calendar->get('tim_hortons'); 
    } 'Exception thrown when invalid field passed to get()';
}

SET_NONEXISTENT_FIELD: {
    my $calendar = Date::Holidays::CA->new();
    dies_ok { 
        $calendar->set({ poutine => 'bien sur' }); 
    } 'Exception thrown when invalid field passed to set()';
}

SET_INVALID_PROVINCE: {
    my $calendar = Date::Holidays::CA->new();
    dies_ok { 
        $calendar->set({ province => 'mi' }); 
    } 'Exception thrown when invalid province given to set()';
}

NEW_NONEXISTENT_FIELD: {
    dies_ok {
        my $calendar = Date::Holidays::CA->new({
            doughnut => 'honey cruller',
        });
    } 'Exception thrown when invalid field name given to new()';
}

NEW_INVALID_PROVINCE: {
    dies_ok {
        my $calendar = Date::Holidays::CA->new({
            province => 'ZZ',
        });
    } 'Exception thrown when invalid province given to new()';
}

# russian not yet implemented =)
NEW_INVALID_LANGUAGE: {
    dies_ok {
        my $calendar = Date::Holidays::CA->new({
            language => 'RU',                     
        });
    } 'Exception thrown when invalid language given to new()'; 
}

