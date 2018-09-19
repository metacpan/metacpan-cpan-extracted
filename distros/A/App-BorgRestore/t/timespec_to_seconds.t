use strictures 2;

use Log::Any::Adapter ('TAP');
use Test::More;

use App::BorgRestore;

my $app = App::BorgRestore->new_no_defaults(undef);

is($app->_timespec_to_seconds('5s'), 5, '5 seconds');
is($app->_timespec_to_seconds('5minutes'), 5*60, '5 minutes');
is($app->_timespec_to_seconds('6d'), 6*60*60*24, '6 days');
is($app->_timespec_to_seconds('8m'), 8*60*60*24*31, '8 months');
is($app->_timespec_to_seconds('2y'), 2*60*60*24*365, '2 years');

is($app->_timespec_to_seconds('5sec'), undef, 'invalid unit returns undef');
is($app->_timespec_to_seconds('5'), undef, 'missing unit returns undef');
is($app->_timespec_to_seconds('blub'), undef, 'string returns undef');
is($app->_timespec_to_seconds(''), undef, 'empty string returns undef');

done_testing;
