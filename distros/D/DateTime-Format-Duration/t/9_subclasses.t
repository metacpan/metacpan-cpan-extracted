use strict;
use warnings;

{
  package My::Datetime;
  use parent 'DateTime';
}

{
  package My::Duration;
  use parent 'DateTime::Duration';
}

use DateTime::Format::Duration;

use Test::More 0.88;
use Test::Fatal;

my $dur = My::Duration->new( hours => 24, minutes => 60 );
is(
    DateTime::Format::Duration->new( pattern => '%P%F %r', normalize => 0 )->format_duration( $dur ),
    '0000-00-00 00:1500:00',
    'DateTime::Duration subclasses accepted without normalization',
);
is(
    DateTime::Format::Duration->new( pattern => '%P%F %r', normalize => 'ISO' )->format_duration( $dur ),
    '0000-00-01 01:00:00',
    'DateTime::Duration subclasses accepted with normalization',
);

is(
    exception {
        my $fmt = DateTime::Format::Duration->new( pattern => '%P%F %r', normalize => 0 );
        $fmt->set_base( My::Datetime->now );
    },
    undef,
    "DateTime subclasses accepted as base"
);

done_testing;
