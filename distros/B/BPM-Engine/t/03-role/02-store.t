use strict;
use warnings;
use Test::More;
use Test::Exception;
use t::TestUtils;

my $user     = $t::TestUtils::user || '';
my $password = $t::TestUtils::password || '';

use_ok('BPM::Engine');

throws_ok( sub { BPM::Engine->new() }, 'BPM::Engine::Exception::Parameter', 'exception thrown' );
throws_ok( sub { BPM::Engine->new(connect_info => [$dsn, $user, $password, { AutoCommit => 1 }] ) }, qr/does not pass the type constraint/, 'wrong type' );

t( BPM::Engine->new(connect_info => { dsn => $dsn, user => $user, password => $password, AutoCommit => 1 }), 0);
t( BPM::Engine->new(connect_info => sub { DBI->connect ($dsn, $user, $password, {AutoCommit => 1 }) } ), 1);
t( BPM::Engine->new(connect_info => { dbh_maker => sub { DBI->connect($dsn, $user, $password) }, AutoCommit => 1 }), 1);

SKIP: {
  skip 'Not local SQLite db', 8 unless ($dsn eq 'dbi:SQLite:dbname=t/var/bpmengine.db');

  t( BPM::Engine->new(connect_info => $dsn), 1);
  t( BPM::Engine->new_with_config(configfile => 't/etc/engine.yaml'), 0);
  t( BPM::Engine->new_with_config(configfile => 't/etc/engine.ini'), 0);
  t( BPM::Engine->new_with_config(configfile => 't/etc/engine.conf'), 0);
  };

done_testing;

sub t {
    my ($engine, $skip) = @_;
    {
        local $SIG{__WARN__} = sub {};
        $engine->schema->storage->ensure_connected;
    }
    ok($engine->schema->storage->connected);
    isa_ok($engine->schema->resultset('Process')->search_rs, 'DBIx::Class::ResultSet');
    #is($engine->schema->resultset('Process')->count, 0);
return;
    unless($skip) {
        my $ci = $engine->schema->storage->_normalize_connect_info($engine->schema->storage->connect_info);
        my $args = $ci->{arguments};
        my $attr = $ci->{attributes};
        is($args->[0], $dsn, 'dsn matches');
        is($args->[1], $user,'user matches');
        is($args->[2], $password,'password matches');
        ok($attr->{AutoCommit}, 'AutoCommit set');
        }
    }
