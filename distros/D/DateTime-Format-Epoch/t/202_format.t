use strict;
BEGIN { $^W = 1 }

use Test::More tests => 19;
use DateTime;
use DateTime::Format::Epoch::MacOS;

my $f = DateTime::Format::Epoch::MacOS->new();

isa_ok($f, 'DateTime::Format::Epoch::MacOS' );

my $dt = DateTime->new( year  => 1904, month => 1, day   => 1 );
is($f->format_datetime($dt), 0, 'Epoch = 0');
is(DateTime::Format::Epoch::MacOS->format_datetime($dt), 0, 'Epoch = 0');

$dt->set( hour => 1 );
is($f->format_datetime($dt), 3600, 'Epoch + 1hour');
is(DateTime::Format::Epoch::MacOS->format_datetime($dt), 3600, 'Epoch + 1hour');

$dt->set( day => 2, hour => 0 );
is($f->format_datetime($dt), 24*3600, 'Epoch + 1day');
is(DateTime::Format::Epoch::MacOS->format_datetime($dt), 24*3600, 'Epoch + 1day');

for my $tz (qw[ UTC floating America/Chicago Europe/Amsterdam
                Australia/Melbourne +1200 ]) {
    $dt = DateTime->new( year => 2003, month => 7, day => 1 );
    is($f->format_datetime($dt), 3139862400, "tz: $tz");
    is(DateTime::Format::Epoch::MacOS->format_datetime($dt), 3139862400, "tz: $tz");
}
