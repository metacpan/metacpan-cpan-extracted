use t::TestCogBase tests => 12;
use diagnostics;

my $db_path = 't/cogbase-test-db';

create_database($db_path);

ok(-d $db_path, 'CogBase database exists');

#-------------------------------------------------------------------------------
# Make a connection to the database;
my $conn = CogBase->connect($db_path);

# Create a schema node for type = 'thought'
my $schema = $conn->node('Schema');
$schema->value(<<'...');
+: thought
<: Node
value: String
...
$conn->store($schema);

# Create an object of type = 'thought'
my $thought = $conn->node('thought');
$thought->value('CogBase is cool');
$conn->store($thought);

#-------------------------------------------------------------------------------
my @results = $conn->query('!thought');

ok(@results == 1, 'One node from query');

is($results[0], 'FFP-V5VPLBO2UI6JQ33LJ7B5GMU-1', 'Node key is correct');

my @nodes = $conn->fetch(@results);

ok(@nodes == 1, 'One node from fetch');

my $node = shift @nodes;

is(ref($node), 'CogBase::thought', 'Fetched node has correct class');
is($node->value, 'CogBase is cool', 'Node value is correct');

#-------------------------------------------------------------------------------
my @results2 = $conn->query('!Schema');

ok(@results2 == 1, 'One node from query');

is($results2[0], 'DPS-SDL3FMUVBQYZZD4LYD354DQ-1', 'Node key is correct');

my @nodes2 = $conn->fetch(@results2);

ok(@nodes2 == 1, 'One node from fetch');

my $node2 = shift @nodes2;

is(ref($node2), 'CogBase::Schema', 'Fetched node has correct class');
is($node2->value, <<'...', 'Node value is correct');
+: thought
<: Node
value: String
...

#-------------------------------------------------------------------------------
$conn->disconnect;
is(ref($conn), 'CogBase::Connection::FileSystem::disconnected',
    'Connection disabled');
