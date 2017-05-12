use lib 't/lib';

use strict;
use warnings;

use Test::More;

use LibraryHelper;

BEGIN { require_ok 'Dallycot::Library::Core::DateTime' };

isa_ok(Dallycot::Library::Core::DateTime->instance, 'Dallycot::Library');

uses 'http://www.dallycot.net/ns/core/1.0#';
uses 'http://www.dallycot.net/ns/loc/1.0#';
uses 'http://www.dallycot.net/ns/date-time/1.0#';

ok(Dallycot::Registry->instance->has_namespace('http://www.dallycot.net/ns/date-time/1.0#'), 'DateTime namespace is registered');

my $result;

$result = run('duration(<1>)');

ok !DateTime::Duration->compare($result->value, Duration(years => 1)->value), "duration(<1>) is one year";

$result = run('P1Y ::> date(<2014,5,31>)');

ok !DateTime->compare($result->value, DateTime->new(year => 2015, month => 5, day => 31)), "31 May 2014 + 1 year = 31 May 2015";

$result = run('1 ::> 2 ::> date(<2014,5,31,23,59,59>)');

ok !DateTime->compare($result->value, DateTime->new(
  year => 2014,
  month => 6,
  day => 1,
  hour => 0,
  minute => 0,
  second => 2
)), "3 seconds after 31 May 2014 23:59:59 is 1 June 2014 0:0:2";

$result = run('duration(date(<2014,1,1>), date(<2015,1,1>))');

ok !DateTime::Duration->compare($result->value, Duration(years => 1)->value), "duration(date(<2014,1,1>), date(<2015,1,1>)) is one year";

$result = run('duration(date(<2015,1,1>), date(<2014,1,1>))');

ok !DateTime::Duration->compare($result->value, Duration(years => -1)->value), "duration(date(<2015,1,1>), date(<2014,1,1>)) is (negative) one year";

done_testing();
