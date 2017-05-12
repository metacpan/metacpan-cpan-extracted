use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 6 );
}

my $schema = DBICTest->init_schema;
my $cursor_class = 'DBIx::Class::Storage::DBI::Cursor';

## master
my $m_itr_artist = $schema->resultset('Artist')->search;
my $m_artist_cursor = $m_itr_artist->cursor;
is(ref $m_artist_cursor,$cursor_class,'master artist "cursor"');

my $m_itr_cd = $schema->resultset('CD')->search;
my $m_cd_cursor = $m_itr_cd->cursor;
is(ref $m_cd_cursor,$cursor_class,'master cd "cursor"');

my $m_itr_track = $schema->resultset('Track')->search;
my $m_track_cursor = $m_itr_track->cursor;
is(ref $m_track_cursor,$cursor_class,'master track "cursor"');

## slave
my $s_itr_artist = $schema->resultset('Artist::Slave')->search;
my $s_artist_cursor = $s_itr_artist->cursor;
is(ref $s_artist_cursor,$cursor_class,'slave artist "cursor"');

my $s_itr_cd = $schema->resultset('CD::Slave')->search;
my $s_cd_cursor = $s_itr_cd->cursor;
is(ref $s_cd_cursor,$cursor_class,'slave cd "cursor"');

my $s_itr_track = $schema->resultset('Track::Slave')->search;
my $s_track_cursor = $s_itr_track->cursor;
is(ref $s_track_cursor,$cursor_class,'slave track "cursor"');
