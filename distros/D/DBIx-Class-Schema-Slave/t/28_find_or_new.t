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

my $schema = DBICTest->init_schema;
my $artist = {artistid => 3,name => 'AIR'};
my $cd = {cdid => 6,artist => 3,title => 'Nayuta',year => 2008};
my $track = {trackid => 51,cd => 6,position => 1,title => "Dawning"};

## master
my $m_artist = $schema->resultset('Artist')->find_or_new($artist);
is($m_artist->is_slave,0,'master artist "find_or_new"');
is($m_artist->name,$artist->{name},'master artist "find_or_new"');

my $m_cd = $schema->resultset('CD')->find_or_new($cd);
is($m_cd->is_slave,0,'master cd "find_or_new"');
is($m_cd->title,$cd->{title},'master cd "find_or_new"');

my $m_track = $schema->resultset('Track')->find_or_new($track);
is($m_track->is_slave,0,'master track "find_or_new"');
is($m_track->title,$track->{title},'master track "find_or_new"');

## slave
my $s_artist = $schema->resultset('Artist::Slave')->find_or_new($artist);
is($s_artist->is_slave,1,'slave artist "find_or_new"');
is($s_artist->name,$artist->{name},'slave artist "find_or_new"');

my $s_cd = $schema->resultset('CD::Slave')->find_or_new($cd);
is($s_cd->is_slave,1,'slave cd "find_or_new"');
is($s_cd->title,$cd->{title},'slave cd "find_or_new"');

my $s_track = $schema->resultset('Track::Slave')->find_or_new($track);
is($s_track->is_slave,1,'slave track "find_or_new"');
is($s_track->title,$track->{title},'slave track "find_or_new"');
