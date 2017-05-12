use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;
use DBICTest::Constants qw/ THROW_EXCEPTION_MESSAGE /;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 12 );
}

my $schema = DBICTest->init_schema;
my $suffix = '_updated';
my $message = THROW_EXCEPTION_MESSAGE;

## master
my $m_artist = $schema->resultset('Artist')->find(1);
my $m_artist_name = $m_artist->name;
$m_artist->name($m_artist->name.$suffix);
$m_artist->update;
is($m_artist->is_slave, 0, 'master artist "update"');
is($m_artist->name,$m_artist_name.$suffix,'master artist "update"');

my $m_cd = $schema->resultset('CD')->find(1);
my $m_cd_title = $m_cd->title;
$m_cd->title($m_cd->title.$suffix);
$m_cd->update;
is($m_cd->is_slave,0,'master cd "update"');
is($m_cd->title,$m_cd_title.$suffix,'master cd "update"');

my $m_track = $schema->resultset('Track')->find(1);
my $m_track_title = $m_track->title;
$m_track->title($m_track->title.$suffix);
$m_track->update;
is($m_track->is_slave,0,'master track "update"');
is($m_track->title,$m_track_title.$suffix,'master track "update"');

## slave
my $s_artist = $schema->resultset('Artist::Slave')->find(1);
my $s_artist_name = $s_artist->name;
$s_artist->name($s_artist->name.$suffix);
eval {$s_artist->update};
is($s_artist->is_slave,1,'slave artist "update"');
like($@,qr/$message/,'slave artist "update"');

my $s_cd = $schema->resultset('CD::Slave')->find(1);
my $s_cd_title = $s_cd->title;
$s_cd->title($s_cd->title.$suffix);
eval{$s_cd->update};
is($s_cd->is_slave,1,'slave cd "update"');
like($@,qr/$message/,'slave artist "update"');

my $s_track = $schema->resultset('Track::Slave')->find(1);
my $s_track_title = $s_track->title;
$s_track->title($s_track->title.$suffix);
eval{$s_track->update};
is($s_track->is_slave,1,'slave track "update"');
like($@,qr/$message/,'slave artist "update"');
