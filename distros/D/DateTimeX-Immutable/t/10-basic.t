use strict;
use warnings;
use Test::More;
use Test::Exception;
use DateTimeX::Immutable;

my $exception = qr/Attempted to mutate a DateTime object/;
my $dt        = DateTimeX::Immutable->new(
    year      => 2014,
    month     => 12,
    day       => 9,
    hour      => 12,
    minute    => 0,
    second    => 0,
    time_zone => 'America/New_York'
);
isa_ok $dt, 'DateTimeX::Immutable';
is $dt->st, '2014-12-09T12:00:00EST', '... equals correct time';

# Old mutators should throw exceptions
my @mutators = qw( add subtract add_duration subtract_duration truncate set
  set_year set_month set_day set_hour set_minute set_second set_nanosecond );
for my $mutator (@mutators) {
    throws_ok { $dt->$mutator() } $exception, "$mutator croaks";
    is $dt->st, '2014-12-09T12:00:00EST', '... and does not mutate';
}

# Now try the new methods
is $dt->plus( minutes => 20 )->st, '2014-12-09T12:20:00EST', 'add 20min';
is $dt->st, '2014-12-09T12:00:00EST', '... and does not mutate';

is $dt->minus( minutes => 20 )->st, '2014-12-09T11:40:00EST',
  'subtract 20min';
is $dt->st, '2014-12-09T12:00:00EST', '... and does not mutate';

is $dt->with_year(2010)->st, '2010-12-09T12:00:00EST', 'year=2010';
is $dt->st, '2014-12-09T12:00:00EST', '... and does not mutate';

is $dt->with_month(11)->st, '2014-11-09T12:00:00EST', 'month=11';
is $dt->st, '2014-12-09T12:00:00EST', '... and does not mutate';

is $dt->with_day(20)->st, '2014-12-20T12:00:00EST', 'day=20';
is $dt->st, '2014-12-09T12:00:00EST', '... and does not mutate';

is $dt->with_hour(20)->st, '2014-12-09T20:00:00EST', 'hour=20';
is $dt->st, '2014-12-09T12:00:00EST', '... and does not mutate';

is $dt->with_minute(20)->st, '2014-12-09T12:20:00EST', 'minute=20';
is $dt->st, '2014-12-09T12:00:00EST', '... and does not mutate';

is $dt->with_second(20)->st, '2014-12-09T12:00:20EST', 'second=20';
is $dt->st, '2014-12-09T12:00:00EST', '... and does not mutate';

is $dt->with_nanosecond(20)->st, '2014-12-09T12:00:00EST', 'nanosecond=20';
is $dt->st, '2014-12-09T12:00:00EST', '... and does not mutate';

is $dt->with_component( minute => 20 )->st, '2014-12-09T12:20:00EST', 'set 20min';
is $dt->st, '2014-12-09T12:00:00EST', '... and does not mutate';

is $dt->trunc( to => 'day' )->st, '2014-12-09T00:00:00EST',
  'truncate to day';
is $dt->st, '2014-12-09T12:00:00EST', '... and does not mutate';

done_testing;
