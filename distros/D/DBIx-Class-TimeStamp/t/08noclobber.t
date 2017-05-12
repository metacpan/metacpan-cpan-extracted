use strict;
use warnings;

use Test::More tests => 9;

use DateTime;
use Time::HiRes;
use Time::Warp qw|to time|;

# Redefine "now" so that we can warp it.  
no warnings 'redefine';
local *DateTime::now = sub { shift->from_epoch( epoch => (scalar time), @_ ) };
use warnings 'redefine';

use lib qw(t/lib);
use DBIC::Test;

my $schema = DBIC::Test->init_schema;
my $row;

my $last_week = DateTime->now() - DateTime::Duration->new( weeks => 1 );

my $t = time(); 
Time::HiRes::sleep (int ($t) + 1 - $t);

$row = $schema->resultset('DBIC::Test::Schema::TestDatetime')
    ->create({ display_name => 'test record', t_created => $last_week });

my $time = $row->t_updated;

ok $row->t_created, 'created timestamp';
ok $row->t_updated, 'updated timestamp';
is   $row->t_created, $last_week, 'create timestamp';
isnt $row->t_updated, $row->t_created, 'update and create timestamp';

to(time + 60);

$row->update({ display_name => 'updating test record' });

is $row->display_name, 'updating test record', 'update record';
isnt $row->t_updated, $time, 'timestamp update';
$time = $row->t_updated;

to(time + 60);

$row->update({
    display_name => 'updating test record again', t_updated => $last_week
});

is $row->display_name, 'updating test record again', 'update record';
isnt $row->t_updated, $time, 'timestamp update';
is $row->t_updated, $row->t_created, 'timestamp update is create now';

