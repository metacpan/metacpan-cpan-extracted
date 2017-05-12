use strict;
use lib 'lib';
use File::Path 'rmtree';
use XXX;

my $db_path = 't/cogbase-test-db';
rmtree($db_path);

use CogBase::Database;

CogBase::Database->create($db_path);

#-------------------------------------------------------------------------------
use CogBase;

# my $conn = CogBase->connect('http://cog.example.com');
my $conn = CogBase->connect($db_path);

my $schema = $conn->node('Schema');
$schema->value(<<'...');
+: person
<: Node
age: Number
given_name: String
family_name: String
...
$conn->store($schema);

my $person = $conn->node('person');

$person->given_name('Ingy');
$person->family_name('dot Net');
$person->age(42);

$conn->store($person);

my @results = $conn->query('!person');
my @nodes = $conn->fetch(@results);

for my $node (@nodes) {
    printf "%s %s is %d years old\n",
        $node->given_name,
        $node->family_name,
        $node->age;
}

$conn->disconnect;
