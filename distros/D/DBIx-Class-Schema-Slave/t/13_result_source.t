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
my $result_source_class = 'DBIx::Class::ResultSource::Table';

## master
my $m_artist_result_source = $schema->resultset('Artist')->result_source;
is(ref $m_artist_result_source,$result_source_class,'master artist "result_source"');

my $m_cd_result_source = $schema->resultset('CD')->result_source;
is(ref $m_cd_result_source,$result_source_class,'master cd "result_source"');

my $m_track_result_source = $schema->resultset('Track')->result_source;
is(ref $m_track_result_source,$result_source_class,'master track "result_source"');

## slave
my $s_artist_result_source = $schema->resultset('Artist::Slave')->result_source;
is(ref $s_artist_result_source,$result_source_class,'slave artist "result_source"');

my $s_cd_result_source = $schema->resultset('CD::Slave')->result_source;
is(ref $s_cd_result_source,$result_source_class,'slave cd "result_source"');

my $s_track_result_source = $schema->resultset('Track::Slave')->result_source;
is(ref $s_track_result_source,$result_source_class,'slave track "result_source"');
