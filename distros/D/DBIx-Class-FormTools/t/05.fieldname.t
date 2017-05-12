use Test::More;
use DBIx::Class::FormTools;

my $field_definition = qr{
    dbic         # Prefix
    \|           # Seperator
    [\w]+        # Object id
    \|           # Seperator
    [\w:]+       # Classname
    \|           # Seperator
    (?:          # Id field
        \d+
        |
        (?:\w+:(?:\d+|new))(?:;\w+:(?:\d+|new))*
    )
    \|           # Seperator
    \w*          # Attribute name (optional)
}x;

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 17);
}

INIT {
    use lib 't/lib';
    use_ok('Test');
}

# Initialize database
my $schema = Test->initialize;
ok($schema, "Schema created");

my $helper = DBIx::Class::FormTools->new({ schema => $schema });
ok($helper,"Helper object created");

# Create test objects
my $film0 = $schema->resultset('Film')->new({
    title   => 'Office Space 0',
    comment => 'Funny film',
});

my $film1 = $schema->resultset('Film')->create({
    title   => 'Office Space',
    comment => 'Funny film',
});

my $film2 = $schema->resultset('Film')->create({
    title   => 'Office Space II',
    comment => 'Funny film',
});

my $film3 = $schema->resultset('Film')->create({
    title   => 'Office Space III',
    comment => 'Funny film',
});

my $actor1 = $schema->resultset('Actor')->create({
    name => 'Samir',
});

# Test as instance methods
my @instance_method_fieldnames = (
    $helper->fieldname($film1, 'title' ,  'o1'),
    $helper->fieldname($film1, 'length',  'o1'),
    $helper->fieldname($film1, 'comment', 'o1'),
    $helper->fieldname($film2, 'title',   'o2'),
    $helper->fieldname($film2, 'length',  'o2'),
    $helper->fieldname($film2, 'comment', 'o2'),
);
# Validate that the fields match the definition
like($_, $field_definition, "fieldname: $_")
    foreach @instance_method_fieldnames;

# Test as class methods
my @class_method_fieldnames = (
    $helper->fieldname($film0, 'title',     'o3'),
    $helper->fieldname($film0, 'length',    'o3'),
    $helper->fieldname($film0, 'comment',   'o3'),
    $helper->fieldname($film0, 'title',     'o4'),
    $helper->fieldname($film0, 'length',    'o4'),
    $helper->fieldname($film0, 'comment',   'o4'),
);
# Validate that the fields match the definition
like($_, $field_definition, "fieldname: $_")
    foreach @class_method_fieldnames;

my $role = $schema->resultset('Role')->new({});

# Many to many without content
ok(1,$helper->fieldname($role,
    undef,
    'o3', {
        film_id  => 'o1',
        actor_id => 'o2',
    })
);

# Many to many with content
ok(1,$helper->fieldname($role,
    'charater',
    'o3', {
        film_id  => 'o1',
        actor_id => 'o2',
    })
);