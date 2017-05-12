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
        : ( tests => 21 );
}

my $schema = DBICTest->init_schema;
my $message = THROW_EXCEPTION_MESSAGE;
my $find_artist = {artistid => 1};
my $find_cd = {cdid => 1};
my $find_track = {trackid => 1};
my $create_artist = {artistid=>undef,name=>'CREATE'};
my $create_cd = {cdid => undef,artist => 1,title => 'CREATE',year => 2008};
my $create_track = {trackid => undef,cd => 9999,position => 1,title => "CREATE"};

## slave
my $s_artist = $schema->resultset('Artist::Slave')->find_or_create($find_artist);
is($s_artist->is_slave,1,'master artist "find_or_create"');
is($s_artist->id,$find_artist->{artistid},'master artist "find_or_create"');
eval{$s_artist = $schema->resultset('Artist::Slave')->find_or_create($create_artist)};
like($@,qr/$message/,'slave cd "find_or_create"');

my $s_cd = $schema->resultset('CD::Slave')->find_or_create($find_cd);
is($s_cd->cdid,$find_cd->{cdid},'slave cd "find_or_create"');
is($s_cd->is_slave,1,'slave cd "find_or_create"');
eval{$s_cd = $schema->resultset('CD::Slave')->find_or_create($create_cd)};
like($@,qr/$message/,'slave cd "find_or_create"');

my $s_track = $schema->resultset('Track::Slave')->find_or_create($find_track);
is($s_track->is_slave,1,'slave track "find_or_create"');
is($s_track->trackid,$find_track->{trackid},'slave track "find_or_create"');
eval{$s_track = $schema->resultset('Track::Slave')->find_or_create($create_track)};
like($@,qr/$message/,'slave track "find_or_create"');

## master
my $m_artist = $schema->resultset('Artist')->find_or_create($find_artist);
is($m_artist->is_slave,0,'master artist "find_or_create"');
is($m_artist->artistid,$find_artist->{artistid},'master artist "find_or_create"');
$m_artist = $schema->resultset('Artist')->find_or_create($create_artist);
is($m_artist->is_slave,0,'master artist "find_or_create"');
is($m_artist->name,$create_artist->{name},'master artist "find_or_create"');

my $m_cd = $schema->resultset('CD')->find_or_create($find_cd);
is($m_cd->is_slave,0,'master cd "find_or_create"');
is($m_cd->cdid,$find_cd->{cdid},'master cd "find_or_create"');
$m_cd = $schema->resultset('CD')->find_or_create($create_cd);
is($m_cd->is_slave,0,'master cd "find_or_create"');
is($m_cd->title,$create_cd->{title},'master cd "find_or_create"');

my $m_track = $schema->resultset('Track')->find_or_create($find_track);
is($m_track->is_slave,0,'master track "find_or_create"');
is($m_track->trackid,$find_track->{trackid},'master track "find_or_create"');
$m_track = $schema->resultset('Track')->find_or_create($create_track);
is($m_track->is_slave,0,'master track "find_or_create"');
is($m_track->title,$create_track->{title},'master track "find_or_create"');
