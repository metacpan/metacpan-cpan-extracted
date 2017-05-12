use strict;
use warnings;

use Test::More;
use lib qw(t/lib);
use DBICTest;

BEGIN {
    eval "use DBD::SQLite; use SQL::Translator";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite and SQL::Translator for testing' )
        : ( tests => 21 );
}

my $schema = DBICTest->init_schema(no_populate => 1);

ok($schema, 'Created a Schema');

isa_ok(
   $schema->_journal_schema,
   'DBIx::Class::Schema::Journal::DB',
   'Actually have a schema object for the journaling'
);

isa_ok(
   $schema->_journal_schema->source('CDAuditHistory'),
   'DBIx::Class::ResultSource',
   'CDAuditHistory source exists'
);

isa_ok(
   $schema->_journal_schema->source('ArtistAuditLog'),
   'DBIx::Class::ResultSource',
   'ArtistAuditLog source exists'
);

my $artist;
my $new_cd = $schema->txn_do( sub {
    my $current_changeset = $schema->_journal_schema->_current_changeset;
    ok( $current_changeset, 'have a current changeset' );

    $artist = $schema->resultset('Artist')->create({
        name => 'Fred Bloggs',
    });

    $schema->txn_do(sub {
        is(
           $current_changeset,
           $schema->_journal_schema->_current_changeset,
           q{nested txn doesn't create a new changeset}
        );
        return $schema->resultset('CD')->create({
            title => 'Angry young man',
            artist => $artist,
            year => 2000,
        });
    });
});
isa_ok(
   $new_cd,
   'DBIx::Class::Journal',
   'Created CD object'
);

is(
   $schema->_journal_schema->_current_changeset,
   undef, 'no current changeset'
);
eval { $schema->_journal_schema->current_changeset };
ok( $@, 'causes error' );

my $search = $schema->_journal_schema->resultset('CDAuditLog')->search;
ok($search->count, 'Created an entry in the CD audit log');

$schema->txn_do(sub {
    $new_cd->year(2003);
    $new_cd->update;
});

is($new_cd->year, 2003,  'Changed year to 2003');
my $cdah = $schema->_journal_schema->resultset('CDAuditHistory')->search;
ok($cdah->count, 'Created an entry in the CD audit history');

$schema->txn_do( sub {
    $schema->resultset('CD')->create({
        title => 'Something',
        artist => $artist,
        year => 1999,
    });
});


my %id = map { $_ => $new_cd->get_column($_) } $new_cd->primary_columns;

$schema->txn_do( sub {
    $new_cd->delete;
});

{
    my $alentry = $search->find(\%id);
    ok($alentry, 'got log entry');
    ok(defined($alentry->deleted), 'Deleted set in audit_log');
    cmp_ok(
       $alentry->deleted->id, '>', $alentry->created->id,
       'deleted is after created'
    );
}

$new_cd = $schema->txn_do( sub {
    $schema->resultset('CD')->create({
        %id,
        title => 'lalala',
        artist => $artist,
        year => 2000,
    });
});

{
    my $alentry = $search->find(\%id);
    ok($alentry, 'got log entry');
    ok(defined($alentry->deleted), 'Deleted set in audit_log');
    cmp_ok(
       $alentry->deleted->id, '<', $alentry->created->id,
       'deleted is before created (recreated)'
    );
}

$schema->changeset_user(1);
$schema->txn_do( sub {
    $schema->resultset('CD')->create({
        title => 'Something 2',
        artist => $artist,
        year => 1999,
    });
});

ok($search->count > 1, 'Created an second entry in the CD audit history');

my $cset = $schema->_journal_schema->resultset('ChangeSet')->find(6);
is($cset->user_id, 1, 'Set user id for 6th changeset');

$schema->changeset_session(1);
$schema->txn_do( sub {
    $schema->resultset('CD')->create({
        title => 'Something 3',
        artist => $artist,
        year => 1999,
    });
} );

my $cset2 = $schema->_journal_schema->resultset('ChangeSet')->find(7);
is($cset2->session_id, 1, 'Set session id for 7th changeset');



