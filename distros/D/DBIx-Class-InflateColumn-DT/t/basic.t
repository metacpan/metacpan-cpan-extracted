use Test::More tests => 2;

use DT;
use DateTime;

use_ok 'DBIx::Class::InflateColumn::DT';

my $inflator = DBIx::Class::InflateColumn::DT->new();

my $dt = DateTime->from_epoch(epoch => time);

my $res_dt = $inflator->_post_inflate_datetime($dt, {});

isa_ok $res_dt, 'DT';
