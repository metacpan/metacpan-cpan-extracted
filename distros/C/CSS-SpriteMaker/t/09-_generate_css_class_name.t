
use strict;
use warnings;

use Test::More;
use Data::Dumper;

use_ok('CSS::SpriteMaker');

# user defined case
{
    my $SpriteMaker = CSS::SpriteMaker->new(
        rc_filename_to_classname => sub {
            my $filename = shift;
            return uc($filename);
        }
    );
    
    is($SpriteMaker->_generate_css_class_name("calendar.png"),
       'CALENDAR.PNG', 
       'custom function works'
    );
}


# default case
{
    my $SpriteMaker = CSS::SpriteMaker->new();

    is($SpriteMaker->_generate_css_class_name(".calendar.png"),
       'calendar',
       '.calendar.png'
    );
    is($SpriteMaker->_generate_css_class_name("--calendar.png"),
       'calendar',
       '--calendar.png'
    );
    is($SpriteMaker->_generate_css_class_name("calendar.png"),
       'calendar', 
       'calendar.png'
    );
    is($SpriteMaker->_generate_css_class_name("calendar@.png"),
       'calendar', 
       'calendar@.png'
    );
    is($SpriteMaker->_generate_css_class_name("calendar-.png"),
       'calendar', 
       'calendar-.png'
    );
    is($SpriteMaker->_generate_css_class_name("calendar.png"),
       'calendar', 
       'calendar .png'
    );
    is($SpriteMaker->_generate_css_class_name("calendar..png"),
       'calendar', 
       'calendar..png'
    );
    is($SpriteMaker->_generate_css_class_name("long.calendar.png"),
       'long-calendar', 
       'long.calendar.png'
    );
    is($SpriteMaker->_generate_css_class_name("long-calendar.png"),
       'long-calendar', 
       'long-calendar.png'
    );
    is($SpriteMaker->_generate_css_class_name("CALENDAR.PNG"),
       'calendar', 
       'CALENDAR.PNG'
    );
    is($SpriteMaker->_generate_css_class_name("calendar-[33pxX33px].png"),
       'calendar-33pxx33px', 
       'CALENDAR.PNG'
    );
}
done_testing();
