use strict;
use warnings;

use Test::More;

use App::MergeCal;

my $app = App::MergeCal->new(
  title     => 'Test',
  calendars => [
    'http://example.com/1.ics',
    '2.ics',
  ],
);

$app->clean_calendars;

for ($app->calendars->@*) {
  isa_ok($_, 'URI');
}

is $app->calendars->[0]->scheme, 'http', 'First calendar is an HTTP URI';
is $app->calendars->[1]->scheme, 'file', 'Second calendar is a file URI';

done_testing;