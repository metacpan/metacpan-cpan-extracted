use strict;
use warnings;
use utf8;

# `warning` test the presence of a warning while `warns` counts the warnings. Given
# that the former conflict with our method, we rename it into the latter.
use Test2::V0 ':DEFAULT', '!warning', '!warns' , 'warning' => { -as => 'warns' };

use App::ArduinoBuilder::Logger;

is(warns { warning 'Test: %s', 'foobar' } , "WARNING: Test: foobar\n");
ok(no_warnings { debug 'won’t be printer' });

App::ArduinoBuilder::Logger::set_log_level('DEBUG');
is(warns { debug 'is printed' } , "DEBUG: is printed\n");

done_testing;
