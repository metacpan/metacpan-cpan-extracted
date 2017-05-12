use strict;
use warnings;

use Test::More;
use lib qw(t/lib);
use DBICTest;

BEGIN {
    eval "use DBD::SQLite; use SQL::Translator";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite and SQL::Translator for testing' )
        : ( tests => 8 );
}

my $schema = DBICTest->init_schema(no_populate => 1, no_deploy => 1);

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

my $count = eval {
    $schema->_journal_schema->resultset('ChangeLog')->count;
};
my $e = $@;

is( $count, undef, 'no count' );
like( $e, qr/table.*changelog/, 'missing table error' );

$schema->journal_schema_deploy();

$count = eval { $schema->_journal_schema->resultset('ChangeLog')->count };

is( $@, '', "no error" );
is( $count, 0, "count is 0" );

