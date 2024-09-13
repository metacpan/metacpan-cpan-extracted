use 5.010_001;
use strict;
use warnings;
use Carp qw/croak/;
use Test::Warn;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::More;
#
# We use Test::More::UTF8 to enable UTF-8 on Test::Builder
# handles (failure_output, todo_output, and output) created
# by Test::More. Requires Test::Simple 1.302210+, and seems
# to eliminate the following error on some CPANTs builds:
#
# > Can't locate object method "e" via package "warnings"
#
use Test::More::UTF8;

BEGIN {
    use_ok('DBIx::Squirrel', database_entities => [qw/db artist artists/]) || print "Bail out!\n";
    use_ok('T::Squirrel',    qw/:var diagdump/)                            || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

db(DBIx::Squirrel->connect(@TEST_DB_CONNECT_ARGS));

my $artist_legacy = db->prepare('SELECT * FROM artists WHERE ArtistId=? LIMIT 1');
my @tests = (
    {line => __LINE__, got => [length($artist_legacy->_private_state->{Hash})], exp => [43]},    ## 43-char Base64 string
    {   line => __LINE__,
        got  => [$artist_legacy->_private_state->{NormalisedStatement}],
        exp  => ['SELECT * FROM artists WHERE ArtistId=? LIMIT 1'],
    },
    {   line => __LINE__,
        got  => [$artist_legacy->_private_state->{OriginalStatement}],
        exp  => ['SELECT * FROM artists WHERE ArtistId=? LIMIT 1'],
    },
    {line => __LINE__, got => [$artist_legacy->_private_state->{Placeholders}], exp => [{}]},
);
foreach my $t (@tests) {
    is_deeply(
        UNIVERSAL::isa($t->{got}, 'CODE') ? $t->{got}->() : $t->{got},
        $t->{exp}, sprintf('A test at line %d%s', $t->{line}, $t->{name} ? " - $t->{name}" : ''),
    );
}

done_testing();
exit;

is( $artist_legacy->{Statement},
    'SELECT * FROM artists WHERE ArtistId=? LIMIT 1',
    'statement with legacy placeholders ok',
);

is($artist_legacy->execute(3), '0E0', 'statement execute ok');

SKIP:
{   skip "DBD\::SQLite $DBD_SQLite_VERSION too old for \$sth->{ParamValues} tests", 1
      unless $DBD_SQLite_VERSION >= 1.56;
    is_deeply($artist_legacy->{ParamValues}, {1 => 3}, 'statement ParamValues ok');
}

my $artist_named = db->prepare('SELECT * FROM artists WHERE ArtistId=:id LIMIT 1');
is($artist_named->{Statement}, $artist_legacy->{Statement}, 'statement with named placeholders ok');
warnings_exist {$artist_named->execute(3)} [qr/Check bind values/, qr/Odd number of elements/],
  'binding positional parameters to named placeholders gives expected warnings',;
is($artist_named->execute(id => 3), '0E0', 'statement execute ok');

SKIP:
{   skip "DBD\::SQLite $DBD_SQLite_VERSION too old for \$sth->{ParamValues} tests", 1
      unless $DBD_SQLite_VERSION >= 1.56;
    is_deeply($artist_named->{ParamValues}, {1 => 3}, 'statement ParamValues ok');
}
is($artist_named->execute(":id" => 3), '0E0', 'statement execute ok');

SKIP:
{   skip "DBD\::SQLite $DBD_SQLite_VERSION too old for \$sth->{ParamValues} tests", 1
      unless $DBD_SQLite_VERSION >= 1.56;
    is_deeply($artist_named->{ParamValues}, {1 => 3}, 'statement ParamValues ok');
}

my $artist_numbered = db->prepare('SELECT * FROM artists WHERE ArtistId=:1 LIMIT 1');
is($artist_numbered->{Statement}, $artist_legacy->{Statement}, 'statement with numbered placeholders ok',);
is($artist_numbered->execute(3),  '0E0',                       'statement execute ok');

SKIP:
{   skip "DBD\::SQLite $DBD_SQLite_VERSION too old for \$sth->{ParamValues} tests", 1
      unless $DBD_SQLite_VERSION >= 1.56;
    is_deeply($artist_numbered->{ParamValues}, {1 => 3}, 'statement ParamValues ok');
}

my $artist_pg = db->prepare('SELECT * FROM artists WHERE ArtistId=$1 LIMIT 1');
is($artist_pg->{Statement}, $artist_legacy->{Statement}, 'statement with Postgres-styled placeholders ok',);
is($artist_pg->execute(3),  '0E0',                       'statement execute ok');

SKIP:
{   skip "DBD\::SQLite $DBD_SQLite_VERSION too old for \$sth->{ParamValues} tests", 1
      unless $DBD_SQLite_VERSION >= 1.56;
    is_deeply($artist_pg->{ParamValues}, {1 => 3}, 'statement ParamValues ok');
}

my $artist_sqlite = db->prepare('SELECT * FROM artists WHERE ArtistId=?1 LIMIT 1');
is($artist_sqlite->{Statement}, $artist_legacy->{Statement}, 'statement with SQLite-styled placeholders ok',);
is($artist_sqlite->execute(3),  '0E0',                       'statement execute ok');

SKIP:
{   skip "DBD\::SQLite $DBD_SQLite_VERSION too old for \$sth->{ParamValues} tests", 1
      unless $DBD_SQLite_VERSION >= 1.56;
    is_deeply($artist_sqlite->{ParamValues}, {1 => 3}, 'statement ParamValues ok');
}

artists(db->prepare('SELECT * FROM artists'));
is(artists->{Statement}, 'SELECT * FROM artists', 'artists helper statement pass-through ok');

artist($artist_legacy);
is(artist->{Statement}, $artist_legacy->{Statement}, 'artist helper statement pass-through ok');
is_deeply(artist->fetchrow_arrayref, [3, 'Aerosmith'], 'first fetchrow_arrayref ok');
is_deeply(artist->fetchrow_arrayref, undef,            'second fetchrow_arrayref undef ok');
ok(!artist->{Active}, 'statement inactive ok');

is(artist(128), '0E0', 'statement execute ok');

SKIP:
{   skip "DBD\::SQLite $DBD_SQLite_VERSION too old for \$sth->{ParamValues} tests", 1
      unless $DBD_SQLite_VERSION >= 1.56;
    is_deeply($artist_legacy->{ParamValues}, {1 => 128}, 'statement ParamValues ok');
}

ok(artist->{Active}, 'statement active ok');
is_deeply(artist->fetchrow_hashref, {ArtistId => 128, Name => 'Rush'}, 'first fetchrow_hashref ok');
is_deeply(artist->fetchrow_hashref, undef,                             'second fetchrow_hashref undef ok');
ok(!artist->{Active}, 'statement inactive ok');

done_testing();
