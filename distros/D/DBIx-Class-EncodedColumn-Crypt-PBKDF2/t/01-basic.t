use strict;
use warnings;
 
use Test::More;
use Dir::Self;
use lib File::Spec->catdir(__DIR__, 'lib');
use lib File::Spec->catdir(__DIR__, '..', 'lib');
 
use_ok('Schema')
    or diag("Failed to load test schema");
 
Schema->load_classes('PBKDF2');
 
my $schema = Schema->connect('dbi:SQLite:dbname=:memory:');
$schema->deploy({});
 
my $row1 = $schema->resultset('PBKDF2')->create({
    hash_defaults => 'test',
    hash_custom   => 'test',
})->discard_changes;
 
ok($row1->hash_defaults_check('test'))
    or diag('Verification for defaults failed');
 
ok(not $row1->hash_defaults_check('test2'))
    or diag('Verification for defaults succeeded for wrong value');
 
ok($row1->hash_custom_check('test'))
    or diag('Verification for custom failed');
 
ok(not $row1->hash_custom_check('test2'))
    or diag('Verification for custom succeeded for wrong value');
 
my $row2 = $schema->resultset('PBKDF2')->create({
    hash_defaults => 'test',
    hash_custom   => 'test',
})->discard_changes;
 
ok($row1->hash_defaults ne $row2->hash_defaults)
    or diag('Hashes for defaults not different for two rows with same input');

ok($row1->hash_custom ne $row2->hash_custom)
    or diag('Hashes for custom not different for two rows with same input');
 
$row1->hash_defaults('test2');
ok($row1->hash_defaults_check('test2'))
    or diag("Failed to change column value for defaults via accessor");
 
$row1->hash_custom('test2');
ok($row1->hash_custom_check('test2'))
    or diag("Failed to change column value for custom via accessor");
 
$row1->update({ hash_defaults => 'test3' })->discard_changes;
ok($row1->hash_defaults_check('test3'))
    or diag("Failed to change column value for defaults via update");
 
$row1->update({ hash_custom => 'test3' })->discard_changes;
ok($row1->hash_defaults_check('test3'))
    or diag("Failed to change column value for custom via update");
 
done_testing();
