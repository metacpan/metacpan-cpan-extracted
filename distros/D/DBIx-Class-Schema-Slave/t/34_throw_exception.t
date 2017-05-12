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
my $message = 'Le travail est du travail';

# master
my $m_artist_rs = $schema->resultset('Artist');
eval{$m_artist_rs->throw_exception($message)};
like($@,qr/$message/,'master artist "throw_exception"');

my $m_cd_rs = $schema->resultset('CD');
eval{$m_cd_rs->throw_exception($message)};
like($@,qr/$message/,'master cd "throw_exception"');

my $m_track_rs = $schema->resultset('Track');
eval{$m_track_rs->throw_exception($message)};
like($@,qr/$message/,'master track "throw_exception"');

# slave
my $s_artist_rs = $schema->resultset('Artist');
eval{$s_artist_rs->throw_exception($message)};
like($@,qr/$message/,'slave artist "throw_exception"');

my $s_cd_rs = $schema->resultset('CD');
eval{$s_cd_rs->throw_exception($message)};
like($@,qr/$message/,'slave cd "throw_exception"');

my $s_track_rs = $schema->resultset('Track');
eval{$s_track_rs->throw_exception($message)};
like($@,qr/$message/,'slave track "throw_exception"');
