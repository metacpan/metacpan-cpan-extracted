use strict;
BEGIN { $^W = 1 }

use Test::More tests => 9;
use DateTime;
use DateTime::Format::Epoch::DotNet;

my $f = DateTime::Format::Epoch::DotNet->new();

isa_ok($f, 'DateTime::Format::Epoch::DotNet' );

my $dt = DateTime->new( year  => 1, month => 1, day   => 1 );
is($f->format_datetime($dt), 0, 'Epoch = 0');
is(DateTime::Format::Epoch::DotNet->format_datetime($dt), 0, 'Epoch = 0');

$dt->set( hour => 1 );
is($f->format_datetime($dt), 3600*1e7, 'Epoch + 1hour');
is(DateTime::Format::Epoch::DotNet->format_datetime($dt), 3600*1e7, 'Epoch + 1hour');

$dt->set( day => 2, hour => 0 );
is($f->format_datetime($dt), 24*3600*1e7, 'Epoch + 1day');
is(DateTime::Format::Epoch::DotNet->format_datetime($dt), 24*3600*1e7, 'Epoch + 1day');

$dt = DateTime->new( year => 100, month => 1, day => 1 );

is($f->format_datetime($dt) - 31241376000000000, 0, '100 AD (object)');
is(DateTime::Format::Epoch::DotNet->format_datetime($dt) - 31241376000000000, 0, '100 AD (class)');
