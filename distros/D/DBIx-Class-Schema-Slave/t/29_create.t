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
        : ( tests => 9 );
}

my $schema = DBICTest->init_schema;
my $message = THROW_EXCEPTION_MESSAGE;
my $artist = {artistid=>undef,name=>'DUMMY'};
my $cd = {cdid => 99,artist => 1,title => 'DUMMY',year => 2008};
my $track = {trackid => undef,cd => 99,position => 1,title => "1"};

## master
my $m_artist = $schema->resultset('Artist')->create($artist);
is($m_artist->is_slave,0,'master artist "create"');
is($m_artist->name,$artist->{name},'master artist "create"');

my $m_cd = $schema->resultset('CD')->create($cd);
is($m_cd->is_slave,0,'master cd "create"');
is($m_cd->title,$cd->{title},'master cd "create"');

my $m_track = $schema->resultset('Track')->create($track);
is($m_track->is_slave,0,'master track "create"');
is($m_track->title,$track->{title},'master track "create"');

## slave
my $s_artist;
eval{$s_artist = $schema->resultset('Artist::Slave')->create($artist)};
like($@,qr/$message/,'slave artist "create"');

my $s_cd;
eval{$s_cd = $schema->resultset('CD::Slave')->create($cd)};
like($@,qr/$message/,'slave cd "create"');

my $s_track;
eval{$s_track = $schema->resultset('Track::Slave')->create($track)};
like($@,qr/$message/,'slave track "create"');
