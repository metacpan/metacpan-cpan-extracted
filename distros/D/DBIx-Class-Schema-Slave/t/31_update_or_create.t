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
        : ( tests => 18 );
}

my $schema = DBICTest->init_schema;
my $message = THROW_EXCEPTION_MESSAGE;
my $update_artist = {artistid => 1,name => 'UPDATE'};
my $update_cd = {cdid => 1,title => 'UPDATE'};
my $update_track = {trackid => 1,title => 'UPDATE'};
my $create_artist = {artistid=>undef,name=>'DUMMY'};
my $create_cd = {cdid => undef,artist => 1,title => 'DUMMY',year => 2008};
my $create_track = {trackid => undef,cd => 9999,position => 1,title => "1"};

## slave
my $s_artist;
eval{$s_artist = $schema->resultset('Artist::Slave')->update_or_create($create_artist)};
like($@,qr/DBIx::Class::ResultSet::update_or_create()/,'slave cd "find_or_create"');
eval{$s_artist = $schema->resultset('Artist::Slave')->update_or_create($update_artist)};
like($@,qr/$message/,'slave cd "find_or_create"');

my $s_cd;
eval{$s_cd = $schema->resultset('CD::Slave')->update_or_create($create_cd)};
like($@,qr/DBIx::Class::ResultSet::update_or_create()/,'slave cd "find_or_create"');
eval{$s_cd = $schema->resultset('CD::Slave')->update_or_create($update_cd)};
like($@,qr/$message/,'slave cd "find_or_create"');

my $s_track;
eval{$s_track = $schema->resultset('Track::Slave')->update_or_create($create_track)};
like($@,qr/DBIx::Class::ResultSet::update_or_create()/,'slave track "find_or_create"');
eval{$s_track = $schema->resultset('Track::Slave')->update_or_create($update_track)};
like($@,qr/$message/,'slave track "find_or_create"');

## master
my $m_artist = $schema->resultset('Artist')->update_or_create($create_artist);
is($m_artist->is_slave,0,'master artist "update_or_create"');
is($m_artist->name,$create_artist->{name},'master artist "update_or_create"');
$m_artist = $schema->resultset('Artist')->update_or_create($update_artist);
is($m_artist->is_slave,0,'master artist "update_or_create"');
is($m_artist->name,$update_artist->{name},'master artist "update_or_create"');

my $m_cd = $schema->resultset('CD')->update_or_create($create_cd);
is($m_cd->is_slave,0,'master cd "update_or_create"');
is($m_cd->title,$create_cd->{title},'master cd "update_or_create"');
$m_cd = $schema->resultset('CD')->update_or_create($update_cd);
is($m_cd->is_slave,0,'master cd "update_or_create"');
is($m_cd->title,$update_cd->{title},'master cd "update_or_create"');

my $m_track = $schema->resultset('Track')->update_or_create($create_track);
is($m_track->is_slave,0,'master track "update_or_create"');
is($m_track->title,$create_track->{title},'master track "update_or_create"');
$m_track = $schema->resultset('Track')->update_or_create($update_track);
is($m_track->is_slave,0,'master track "update_or_create"');
is($m_track->title,$update_track->{title},'master track "update_or_create"');
