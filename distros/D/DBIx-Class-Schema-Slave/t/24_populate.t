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
        : ( tests => 25 );
}

my $schema = DBICTest->init_schema;
my $message = THROW_EXCEPTION_MESSAGE;
my @artist = ({artistid => undef,name => 'DUMMY'});
my @cd = ({cdid => undef,artist => 1,title => 'DUMMY',year => 2008});
my @track = (
    {trackid => undef,cd => 99,position => 1,title => "1"},
    {trackid => undef,cd => 99,position => 2,title => "2"},
    {trackid => undef,cd => 99,position => 3,title => "3"},
    {trackid => undef,cd => 99,position => 4,title => "4"},
    {trackid => undef,cd => 99,position => 5,title => "5"},
    {trackid => undef,cd => 99,position => 6,title => "6"},
    {trackid => undef,cd => 99,position => 7,title => "7"},
    {trackid => undef,cd => 99,position => 8,title => "8"},
    {trackid => undef,cd => 99,position => 9,title => "9"},
);

## slave

my $s_artist_rs = $schema->resultset('Artist::Slave');
eval{my $tmp = $s_artist_rs->populate(\@artist)};
like($@,qr/$message/,'slave artist "populate"');

my $s_cd_rs = $schema->resultset('CD::Slave');
eval{my $tmp = $s_cd_rs->populate(\@cd)};
like($@,qr/$message/,'slave cd "populate"');

my $s_track_rs = $schema->resultset('Track::Slave');
eval{my $tmp = $s_track_rs->populate( \@track )};
like($@,qr/$message/,'slave track "populate"');

## master
my $m_artist_rs = $schema->resultset('Artist');
my ( $m_artist ) = $m_artist_rs->populate(\@artist);
is($m_artist->is_slave,0,'master artist "populate"');
is($m_artist->name,'DUMMY','master artist "populate"');

my $m_cd_rs = $schema->resultset('CD');
my ( $m_cd ) = $m_cd_rs->populate(\@cd);
is($m_cd->is_slave,0,'master cd "populate"');
is($m_cd->title,'DUMMY','master cd "populate"');

my $m_track_rs = $schema->resultset('Track');
my ( @m_track ) = $m_track_rs->populate( \@track );
my $count = 0;
foreach my $m_track ( @m_track ) {
    is($m_track->is_slave,0,'master track "populate"');    
    is($m_track->title,$track[$count]->{title},'master track "populate"');
    $count++;
}
