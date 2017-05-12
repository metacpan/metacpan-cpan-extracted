use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 12 );
}

my $artist = {artistid => 3,name => 'AIR'};
my $cd = {cdid => 6,artist => 3,title => 'Nayuta',year => 2008};
my $track = {trackid => 51,cd => 6,position => 1,title => "Dawning"};

my $schema = DBICTest->init_schema;

## master
my $m_artist = $schema->resultset('Artist')->new_result($artist);
is($m_artist->is_slave,0,'master artist "new_result"');
is($m_artist->name,$artist->{name},'master artist "new_result"');

my $m_cd = $schema->resultset('CD')->new_result($cd);
is($m_cd->is_slave,0,'master cd "new_result"');
is($m_cd->title,$cd->{title},'master cd "new_result"');

my $m_track = $schema->resultset('Track')->new_result($track);
is($m_track->is_slave,0,'master track "new_result"');
is($m_track->title,$track->{title},'master track "new_result"');

## slave
my $s_artist = $schema->resultset('Artist::Slave')->new_result($artist);
is($s_artist->is_slave,1,'slave artist "new_result"');
is($s_artist->name,$artist->{name},'slave artist "new_result"');

my $s_cd = $schema->resultset('CD::Slave')->new_result($cd);
is($s_cd->is_slave,1,'slave cd "new_result"');
is($s_cd->title,$cd->{title},'slave cd "new_result"');

my $s_track = $schema->resultset('Track::Slave')->new_result($track);
is($s_track->is_slave,1,'slave track "new_result"');
is($s_track->title,$track->{title},'slave track "new_result"');
