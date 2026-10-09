#!perl
use strict;
use warnings;
use English qw( -no_match_vars );

# $data follows the Dancer2::Core::Role::SessionFactory contract.
## no critic (Bangs::ProhibitVagueNames)

# Dancer2::Session::Pg against a real PostgreSQL.
#
# The DDL is not written here. It is EXTRACTED FROM THE MODULE'S OWN POD, so the
# table the documentation tells you to create is the table these tests run
# against. A documented schema that drifts from the working one is the failure
# this arrangement exists to prevent.
#
# Each property that justifies a PostgreSQL-specific engine is checked by
# OBSERVING the database rather than by trusting the module.

use Test2::V1 qw( -utf8 -x ), -include => [ [ 'Test2::Tools::Subtest', 'subtest_streamed' ] ];

use FindBin qw( $Bin );    ## no critic (Community::DiscouragedModules) -- how a test finds t/lib; the warning is for applications
use lib "$Bin/lib";
use SessionPgTest::PgDB   ();
use SessionPgTest::Ddl    ();
use Dancer2::Session::Pg  ();
use Crypt::Digest::SHA256 qw( sha256_hex );

# The id column holds SHA-256 of the session id, so a test reaching into the
# table by id has to hash it the same way the engine does.
sub rid { my ($id) = @_; return sha256_hex($id) }

use DBI     ();
use DBD::Pg qw( :pg_types );

my $WITH    = 'sesswith';       # table that has the optional principal column
my $WITHOUT = 'sesswithout';    # table that does not
my $FK      = 'sessfk';         # table where that column is a real foreign key
my $KEY32   = 'a' x 64;

my ($dbh) = SessionPgTest::PgDB::provision() or T2->skip_all($SessionPgTest::PgDB::REASON);

# This subtest creates the schemas every subtest below depends on, which is why
# it is first and why its failure is worth reading before any other.
T2->subtest_streamed(
    'all three documented DDL variants apply verbatim' => sub {
        for my $case (
            [ $WITH,    'DDL' ],
            [ $WITHOUT, 'DDL without the principal column' ],
            [ $FK,      'DDL with the principal column as a foreign key' ],
        ) {
            my ( $schema, $section ) = @{$case};
            T2->ok( SessionPgTest::Ddl::apply( $dbh, $schema, $section ), "the documented DDL from '$section' applies verbatim" )
              or T2->diag($SessionPgTest::Ddl::REASON);
        }

        # The COMMENT ON statements are part of that DDL, so if they were malformed
        # the loop above would have thrown. Confirm one landed, rather than assume it.
        my ($comment) = $dbh->selectrow_array("SELECT obj_description('$WITH.sessions'::regclass, 'pg_class')");
        T2->like( $comment, qr/Dancer2::Session::Pg/msx, 'the table COMMENT is in the database' );
    }
);

my $DSN = 'dbi:Pg:' . $dbh->{'Name'};

# `key` and `alg` here are scaffolding, not API: the engine takes only
# encryption_keys, and spelling the whole slot out at every call site would bury
# what each test is about.
sub engine {
    my (%args) = @_;
    my $key    = defined $args{'key'} ? delete $args{'key'} : $KEY32;
    my $alg    = delete $args{'alg'} || 'AES-256-GCM';
    my $slots  = delete $args{'encryption_keys'}
      || { 0 => { key => $key, alg => $alg, active => 1 } };
    delete $args{'key'};

    return Dancer2::Session::Pg->new(
        dsn              => $DSN,
        dbuser           => $dbh->{'Username'},
        dbschema         => $WITH,
        dbtable          => 'sessions',
        encryption_keys  => $slots,
        principal_key    => 'principal',
        session_duration => 900,
        %args,
    );
}

my $engine = engine();

my $raw = sub {
    my ( $id, $schema ) = @_;
    $schema ||= $WITH;
    my $row = $dbh->selectrow_arrayref( "SELECT session_data FROM $schema.sessions WHERE id = ?", undef, rid($id) );
    return $row ? $row->[0] : undef;
};

T2->subtest_streamed(
    'a session round trips, and one row stays one row' => sub {
        my $data = { principal => 'PRL-123', oidc => { token => 'SECRET-TOKEN-VALUE' }, n => 42 };
        $engine->_flush( 'sess-1', $data );
        T2->is( $engine->_retrieve('sess-1'), $data, 'a session round trips intact' );
        T2->ok( index( $raw->('sess-1'), 'SECRET-TOKEN-VALUE' ) < 0, 'the token does NOT appear in the stored bytes' );

        my ($clear) = $dbh->selectrow_array( "SELECT principal_id FROM $WITH.sessions WHERE id = ?", undef, rid('sess-1') );
        T2->is( $clear, 'PRL-123', 'the principal id IS in its clear column' );

        $engine->_flush( 'sess-1', { %{$data}, n => 43 } );
        my ($count) = $dbh->selectrow_array( "SELECT count(*) FROM $WITH.sessions WHERE id = ?", undef, rid('sess-1') );
        T2->is( $count,                              1,  'ON CONFLICT updates in place' );
        T2->is( $engine->_retrieve('sess-1')->{'n'}, 43, 'the update took' );
    }
);

# Dancer2::Core::Role::SessionFactory documents session_duration as "duration in
# seconds before sessions should expire, regardless of cookie expiration ... a
# limit on session validity". A limit that every write pushes further away is not
# a limit: a session in continuous use would never reach it, which is precisely
# the session an attacker holding stolen cookies is using.
T2->subtest_streamed(
    'session_duration is an absolute cap, not an idle timeout' => sub {
        $engine->_flush( 'cap-1', { v => 1 } );
        my ($first) = $dbh->selectrow_array( "SELECT expires FROM $WITH.sessions WHERE id = ?", undef, rid('cap-1') );
        $dbh->do('SELECT pg_sleep(1)');
        $engine->_flush( 'cap-1', { v => 2 } );
        my ($later) = $dbh->selectrow_array( "SELECT expires FROM $WITH.sessions WHERE id = ?", undef, rid('cap-1') );

        T2->is( $later, $first,                        'a later write does NOT push expiry out -- the cap runs from creation' );
        T2->is( $engine->_retrieve('cap-1')->{'v'}, 2, 'while the data is still updated' );
    }
);

T2->subtest_streamed(
    'expiry is the server clock decision' => sub {
        $dbh->do( "UPDATE $WITH.sessions SET expires = now() - interval '1 second' WHERE id = ?", undef, rid('sess-1') );
        T2->is( scalar $engine->_retrieve('sess-1'), undef, 'an expired session is not returned' );
        T2->is( $engine->reap,                       1,     'reap removes exactly the expired row' );
    }
);

T2->subtest_streamed(
    'revocation, then fixation and destroy' => sub {
        $engine->_flush( "rev-$_", { principal => 'PRL-999' } ) for 1 .. 3;
        $engine->_flush( 'keep-1', { principal => 'PRL-OTHER' } );
        T2->is( scalar @{ $engine->sessions_for_principal('PRL-999') }, 3, 'three sessions for one principal' );
        T2->is( $engine->destroy_for_principal('PRL-999'),              3, 'all revoked at once' );
        T2->ok( defined $engine->_retrieve('keep-1'), 'another principal is untouched' );

        # Renaming a row cannot be a rename: the payload is sealed against its
        # session id, so _change_id has to re-seal it under the new one. If it did
        # not, fixation protection would silently log every user out at login.
        $engine->_change_id( 'keep-1', 'keep-2' );
        T2->is( scalar $engine->_retrieve('keep-1'), undef, 'the old id is gone' );
        T2->is(
            $engine->_retrieve('keep-2'),
            { principal => 'PRL-OTHER' },
            'and the row moved WITH ITS CONTENTS -- re-sealed under the new id'
        );

        my ($rows) = $dbh->selectrow_array( "SELECT count(*) FROM $WITH.sessions WHERE id = ?", undef, rid('keep-2') );
        T2->is( $rows, 1, 'as one row, not a copy' );

        $engine->_destroy('keep-2');
        T2->is( scalar $engine->_retrieve('keep-2'), undef, 'destroy removes it' );

        # A row that cannot be read has nothing to carry across, so _change_id
        # removes it rather than leaving a payload nobody can open under a fresh id.
        $engine->_flush( 'unreadable-1', { v => 1 } );
        $dbh->do( "UPDATE $WITH.sessions SET session_data = '\\x00' WHERE id = ?", undef, rid('unreadable-1') );
        $engine->_change_id( 'unreadable-1', 'unreadable-2' );
        my ($remaining) = $dbh->selectrow_array( "SELECT count(*) FROM $WITH.sessions WHERE id IN (?,?)",
            undef, rid('unreadable-1'), rid('unreadable-2') );
        T2->is( $remaining, 0, 'an unreadable row is deleted by _change_id, not renamed' );
    }
);

# THE ROLE'S OWN USE FOR sessions(): a cleaning script. It only works because
# destroy_row takes what the id column holds, which destroy() does not.
T2->subtest_streamed(
    'sessions() can be iterated and deleted, which is what the role documents' => sub {
        $engine->_flush( "iter-$_", { principal => 'PRL-I', n => $_ } ) for 1 .. 3;

        my $rows = $engine->sessions;
        T2->ok( ref $rows eq 'ARRAY',                             '_sessions returns an arrayref, as the role requires' );
        T2->ok( ( scalar grep { $_ eq rid('iter-1') } @{$rows} ), 'and the rows are there, by digest' );

        # The trap: the value from sessions() is NOT what destroy() takes.
        my $before = $engine->count_sessions->{'live'};
        T2->like(
            dies { $engine->destroy_row('iter-1') },
            qr/64[ ]hex[ ]characters/msx,
            'passing a SESSION id to destroy_row croaks instead of deleting nothing'
        );
        T2->is( $engine->count_sessions->{'live'}, $before, 'and nothing was deleted' );

        # The documented loop.
        my $deleted = 0;
        $deleted += $engine->destroy_row($_) for map { rid("iter-$_") } 1 .. 3;
        T2->is( $deleted,                              3,     'destroy_row removes one row per call and says so' );
        T2->is( scalar $engine->_retrieve('iter-2'),   undef, 'the sessions are gone' );
        T2->is( $engine->destroy_row( rid('iter-1') ), 0,     'deleting an absent row reports 0, not 1' );
    }
);

# WHAT A DATABASE DUMP IS WORTH, which is the other half of "encrypted at rest".
# The session id IS the cookie, so storing it verbatim would put a working
# credential for every unexpired session in every backup -- no key required.
T2->subtest_streamed(
    'a dump yields no replayable session id' => sub {
        $engine->_flush( 'dump-victim', { principal => 'PRL-D', admin => 1 } );

        # Everything an attacker gets from `pg_dump` of this table.
        my $dumped = $dbh->selectall_arrayref("SELECT id FROM $WITH.sessions");
        my @ids    = map { $_->[0] } @{$dumped};

        T2->ok( scalar @ids, 'the dump has rows' );
        T2->is( scalar( grep { $_ eq 'dump-victim' } @ids ),      0, 'and NONE of them is the session id itself' );
        T2->is( scalar( grep { $_ eq rid('dump-victim') } @ids ), 1, 'the row is found by digest instead' );

        # EVERY id, not the first one: the claim is a property of the whole
        # column, and a regression that stored a later session id verbatim
        # would have passed a check of @ids[0] alone.
        ## no critic (RegularExpressions::ProhibitEnumeratedClasses) -- hex is ASCII; [[:xdigit:]] is Unicode-aware and allows A-F, which sha256_hex never emits
        my @not_digests = grep { !m/\A[0-9a-f]{64}\z/msx } @ids;
        T2->is( [@not_digests], [], 'every stored id in the dump is a SHA-256 digest' );

        # The crucial part: presenting what the dump contains does not work.
        # Dancer2 would hand `id` straight to _retrieve as the cookie value.
        T2->is( scalar $engine->_retrieve( rid('dump-victim') ), undef, 'replaying the stored value as a cookie opens nothing' );
        T2->is( $engine->_retrieve('dump-victim')->{'admin'},    1,     'while the real cookie still works' );
    }
);

# THE ATTACK THIS BINDING EXISTS TO CLOSE, end to end against PostgreSQL.
# Before the session id went in as additional authenticated data, the tag
# covered the payload and nothing else, so a sealed payload was portable between
# rows: this test passed the administrator's session straight to the attacker.
T2->subtest_streamed(
    'a sealed payload cannot be moved to another row' => sub {
        $engine->_flush( 'victim-admin',  { principal => 'PRL-ADMIN', admin => 1 } );
        $engine->_flush( 'victim-attack', { principal => 'PRL-EVIL',  admin => 0 } );

        my ($admin_blob) =
          $dbh->selectrow_array( "SELECT session_data FROM $WITH.sessions WHERE id = ?", undef, rid('victim-admin') );

        # Write access to the table, and NO encryption key.
        my $sth = $dbh->prepare("UPDATE $WITH.sessions SET session_data = ? WHERE id = ?");
        $sth->bind_param( 1, $admin_blob, { pg_type => PG_BYTEA } );
        $sth->bind_param( 2, rid('victim-attack') );
        $sth->execute;

        T2->is( scalar $engine->_retrieve('victim-attack'),
            undef, 'the relocated payload does not decrypt -- no privilege escalation' );
        T2->is( $engine->_retrieve('victim-admin')->{'admin'}, 1, 'while the row it was copied from is untouched and still works' );
    }
);

T2->subtest_streamed(
    'tampering and a wrong key both fail closed' => sub {
        $engine->_flush( 'tamper', { principal => 'PRL-T', admin => 0 } );
        my $blob    = $raw->('tamper');
        my $flipped = ( ord substr $blob, -1 ) ^ 0xFF;
        substr $blob, -1, 1, chr $flipped;
        my $sth = $dbh->prepare("UPDATE $WITH.sessions SET session_data = ? WHERE id = ?");
        $sth->bind_param( 1, $blob, { pg_type => PG_BYTEA } );
        $sth->bind_param( 2, rid('tamper') );
        $sth->execute;
        T2->is( scalar $engine->_retrieve('tamper'), undef, 'an altered payload does not decrypt' );

        $engine->_flush( 'k-1', { principal => 'PRL-K' } );
        T2->is( scalar engine( key => q{b} x 64 )->_retrieve('k-1'), undef, 'the wrong key yields nothing, not garbage' );
    }
);

# The table in this schema has no `principal` column at all. An application with
# no principal concept must work here, untouched.
T2->subtest_streamed(
    'the optional column is genuinely optional' => sub {
        my $plain = Dancer2::Session::Pg->new(
            dsn              => $DSN,
            dbuser           => $dbh->{'Username'},
            dbschema         => $WITHOUT,
            dbtable          => 'sessions',
            encryption_keys  => { 0 => { key => $KEY32, alg => q{AES-256-GCM}, active => 1 } },
            session_duration => 900
        );

        $plain->_flush( 'anon-1', { cart => [ 1, 2, 3 ], step => 'address' } );
        T2->is(
            $plain->_retrieve('anon-1'),
            { cart => [ 1, 2, 3 ], step => 'address' },
            'without principal_key, a table with no principal column works'
        );
        T2->is( $plain->reap, 0, 'reap works there too' );
        T2->ok( defined $plain->_sessions && @{ $plain->_sessions }, '_sessions works there too' );

        T2->ok( !eval { $plain->destroy_for_principal('PRL-X'); 1 },
            'destroy_for_principal refuses when principal_key is not configured' );
        T2->like( $EVAL_ERROR, qr/principal_key/msx, 'and says why' );
        T2->ok( !eval { $plain->sessions_for_principal('PRL-X'); 1 }, 'sessions_for_principal refuses too' );
    }
);

T2->subtest_streamed(
    'every advertised algorithm, against a real table' => sub {
        my %keylen = (
            'AES-128-GCM'       => 16,
            'AES-192-GCM'       => 24,
            'AES-256-GCM'       => 32,
            'ChaCha20-Poly1305' => 32,
        );
        T2->is( [ Dancer2::Session::Pg->algorithms ], [ sort keys %keylen ], 'algorithms() lists what is documented' );

        for my $alg ( sort keys %keylen ) {
            my $e = engine( alg => $alg, key => q{c} x ( 2 * $keylen{$alg} ) );
            $e->_flush( "alg-$alg", { principal => 'PRL-A', secret => 'ALG-SECRET' } );
            T2->is( $e->_retrieve("alg-$alg")->{'secret'}, 'ALG-SECRET', "$alg round trips" );
            T2->ok( index( $raw->("alg-$alg"), 'ALG-SECRET' ) < 0, "$alg leaves nothing readable" );
        }
    }
);

T2->subtest_streamed(
    'construction refuses the impossible' => sub {
        my $one_slot = { 0 => { key => $KEY32, alg => 'AES-256-GCM', active => 1 } };

        T2->ok( !eval { engine( alg => 'AES-128-GCM' ); 1 }, 'a 32-byte key is refused for a slot whose alg needs 16' );
        T2->ok( !eval { engine( alg => 'NO-SUCH-ALG' ); 1 }, 'an unknown alg is refused' );
        T2->ok(
            !eval {
                Dancer2::Session::Pg->new( encryption_keys => $one_slot, dbtable => 'sessions' );
                1;
            },
            'neither dsn nor dbh is refused'
        );
        T2->ok(
            !eval { Dancer2::Session::Pg->new( dsn => $DSN, encryption_keys => $one_slot ); 1 },
            'a missing dbtable is refused -- there is nothing sensible to guess'
        );
    }
);

T2->subtest_streamed(
    'a supplied handle, and an interchangeable serialiser' => sub {
        my $injected = Dancer2::Session::Pg->new(
            dbh              => $dbh,
            dbschema         => $WITH,
            dbtable          => 'sessions',
            encryption_keys  => { 0 => { key => $KEY32, alg => q{AES-256-GCM}, active => 1 } },
            principal_key    => 'principal',
            session_duration => 900
        );
        $injected->_flush( 'inj-1', { principal => 'PRL-INJ', v => 'via-handle' } );
        T2->is( $injected->_retrieve('inj-1')->{'v'}, 'via-handle', 'a supplied dbh works' );

        my $via_code = Dancer2::Session::Pg->new(
            dbh              => sub { $dbh },
            dbschema         => $WITH,
            dbtable          => 'sessions',
            encryption_keys  => { 0 => { key => $KEY32, alg => q{AES-256-GCM}, active => 1 } },
            session_duration => 900
        );
        T2->is( $via_code->_retrieve('inj-1')->{'v'}, 'via-handle', 'a coderef returning a dbh works' );

        T2->is( engine( json_module => 'JSON::PP' )->_retrieve('inj-1')->{'v'},
            'via-handle', 'JSON::PP reads what JSON::MaybeXS wrote' );
    }
);

# The module must NOT assume "public". Given no schema it refers to the table
# unqualified and lets the connection's search_path decide, which is how a
# deployment whose default schema is called something else expects it to behave.
T2->subtest_streamed(
    'no dbschema: the bare table name, resolved by search_path' => sub {
        my $own = DBI->connect( $DSN, $dbh->{'Username'}, undef, { RaiseError => 1, PrintError => 0, AutoCommit => 1 } );
        $own->do("SET search_path TO $WITHOUT");

        my $bare = Dancer2::Session::Pg->new(
            dbh              => $own,
            dbtable          => 'sessions',
            encryption_keys  => { 0 => { key => $KEY32, alg => q{AES-256-GCM}, active => 1 } },
            session_duration => 900
        );

        $bare->_flush( 'bare-1', { v => 'found via search_path' } );
        T2->is(
            $bare->_retrieve('bare-1')->{'v'},
            'found via search_path',
            'with no dbschema the table is referenced bare and search_path resolves it'
        );

        my ($n) = $own->selectrow_array( "SELECT count(*) FROM $WITHOUT.sessions WHERE id = ?", undef, rid('bare-1') );
        T2->is( $n, 1, 'and the row landed in the schema search_path names' );
        $own->disconnect;
    }
);

# This used to crash. count_sessions named principal_id unconditionally, so on
# the table from "DDL without the principal column" -- a table this module's own
# documentation tells you to create -- it raised
#   ERROR: column "principal_id" does not exist
# and no test called it at all. `signed_in` is now ABSENT rather than zero there,
# because the column need not exist and no query could answer it.
T2->subtest_streamed(
    'count_sessions, on every shape of table' => sub {
        my $counted = engine();

        # Earlier subtests have left rows in this table, so measure the DELTA. An
        # absolute expectation here is a test that breaks whenever a test above it
        # is added, which is how a suite stops being trusted.
        my $before = $counted->count_sessions;

        $counted->_flush( "cnt-$_",   { principal => 'PRL-C' } ) for 1 .. 2;
        $counted->_flush( 'cnt-anon', { cart      => [1] } );
        $counted->_flush( 'cnt-old',  { principal => 'PRL-C' } );
        $dbh->do( "UPDATE $WITH.sessions SET expires = now() - interval '1 s' WHERE id = ?", undef, rid('cnt-old') );

        my $with = $counted->count_sessions;
        T2->is( $with->{'signed_in'} - $before->{'signed_in'},
            2, 'with a principal column, signed_in counts the live ones carrying a principal' );
        T2->is( $with->{'expired'} - $before->{'expired'}, 1, 'and expired counts what reap would remove' );
        T2->is( $with->{'live'} - $before->{'live'}, 3, 'and live counts every session that has not expired, principal or not' );

        my $plainly = Dancer2::Session::Pg->new(
            dsn              => $DSN,
            dbuser           => $dbh->{'Username'},
            dbschema         => $WITHOUT,
            dbtable          => 'sessions',
            encryption_keys  => { 0 => { key => $KEY32, alg => q{AES-256-GCM}, active => 1 } },
            session_duration => 900
        );

        my $without = $plainly->count_sessions;
        T2->ok( !exists $without->{'signed_in'}, 'without principal_key, count_sessions OMITS signed_in rather than crashing' );
        T2->is( [ sort keys %{$without} ], [ 'expired', 'live' ], 'and returns exactly the two it can' );
        T2->ok( $without->{'live'} >= 1, 'with a live count that is real' );
    }
);

# The DDL for this came out of the POD like the others, so the foreign key the
# documentation offers is one that has been applied. Here the column is called
# account_id, is a bigint, and references a table -- which is three things the
# free-text case never exercises.
T2->subtest_streamed(
    'the principal column as a foreign key' => sub {
        $dbh->do("INSERT INTO $FK.accounts (id, email) VALUES (7, 'seven\@example.com')");
        $dbh->do("INSERT INTO $FK.accounts (id, email) VALUES (8, 'eight\@example.com')");

        my $fk = Dancer2::Session::Pg->new(
            dsn              => $DSN,
            dbuser           => $dbh->{'Username'},
            dbschema         => $FK,
            dbtable          => 'sessions',
            encryption_keys  => { 0 => { key => $KEY32, alg => q{AES-256-GCM}, active => 1 } },
            principal_column => 'account_id',
            principal_key    => sub { return $_[0]->{'user'}{'id'} },                             # a coderef, not a key name
            session_duration => 900,
        );

        $fk->_flush( "fk-$_",    { user => { id => 7, name => 'ignored' } } ) for 1 .. 2;
        $fk->_flush( 'fk-other', { user => { id => 8 } } );

        my ($stored) = $dbh->selectrow_array( "SELECT account_id FROM $FK.sessions WHERE id = ?", undef, rid('fk-1') );
        T2->is( $stored, 7, 'a coderef principal_key lands in the renamed column' );

        T2->is( scalar @{ $fk->sessions_for_principal(7) }, 2, 'and is queryable through the index' );
        T2->is( $fk->count_sessions->{'signed_in'},         3, 'and counted by count_sessions' );
        T2->is( $fk->destroy_for_principal(7),              2, 'and revocable, two of the three' );
        T2->ok( defined $fk->_retrieve('fk-other'), 'leaving the other account alone' );

        # ON DELETE CASCADE is the reason to use a foreign key at all: the account
        # going away ends its sessions in the same statement, with no application
        # code to forget.
        $dbh->do("DELETE FROM $FK.accounts WHERE id = 8");
        T2->is( scalar $fk->_retrieve('fk-other'), undef, 'ON DELETE CASCADE removed the session when its account was deleted' );

        # And the consequence the POD warns about, verified rather than asserted: a
        # principal that is not a row in the referenced table FAILS THE WRITE. That
        # is the constraint doing its job, and it is also an outage for one user.
        T2->ok(
            !eval { $fk->_flush( 'fk-ghost', { user => { id => 999 } } ); 1 },
            'a principal absent from the referenced table makes the session write fail'
        );
        T2->like( $EVAL_ERROR, qr/foreign[ ]key/msx, 'with the constraint named' );

        # A non-numeric value against a bigint column, likewise.
        T2->ok( !eval { $fk->_flush( 'fk-text', { user => { id => 'anonymous' } } ); 1 },
            'and so does a value the column type cannot hold' );
    }
);

T2->done_testing;
