use strict;
use warnings;

use Test::More;

use App::MergeCal;

ok(my $app = App::MergeCal->new(
  title     => 'Test',
  calendars => [
    'http://example.com/1.ics',
    'http://example.com/2.ics',
  ],
), 'Got an object');

isa_ok($app, 'App::MergeCal');

can_ok($app, qw[run gather render]);

is($app->calendars->@*, 2, 'Correct number of calendars');
is($app->title, 'Test', 'Correct title');

done_testing;
