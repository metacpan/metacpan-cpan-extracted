use Test::More;
use Data::Dump 'pp';

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 10);
}

INIT {
    use lib 't/lib';
    use_ok( 'DBIx::Class::FormTools' );
    use_ok('Test');
}

# Initialize database
my $schema = Test->initialize;
ok($schema, "Schema created");

my $helper = DBIx::Class::FormTools->new({ schema => $schema });
ok($helper,"Helper object created");

# Create test objects
my $film = $schema->resultset('Film')->create({
    title   => 'Office Space',
    comment => 'Funny film',
});

my $actor = $schema->resultset('Actor')->create({
    name   => 'Cartman',
});

my $role = $schema->resultset('Role')->new({
#    charater => 'The New guy',
});

my $formdata = {
    $helper->fieldname($film, 'title',   'o1') => 'Bigger longer uncut',
    $helper->fieldname($film, 'length',  'o1') => 42,
    $helper->fieldname($film, 'comment', 'o1') => 'Damn, they swear!',
    $helper->fieldname($actor, 'name',   'o2') => 'Cartman',
    $helper->fieldname($role,   undef,   'o3', {
        film_id  => 'o1',
        actor_id => 'o2',
    }) => 'Fat kid',
};
ok(1,"Formdata created:\n".pp($formdata));

my $objects = $helper->formdata_to_object_hash($formdata);
ok(keys %$objects == 3, 'Excacly three object retrieved');
isa_ok($objects->{o1}, 'Schema::Film', 'Object is a Film.');
isa_ok($objects->{o2}, 'Schema::Actor', 'Object is a Actor.');
isa_ok($objects->{o3}, 'Schema::Role', 'Object is a Role.');

print 'Final objects: '.pp($objects) ."\n"
    if $ENV{DBIX_CLASS_FORMTOOLS_DEBUG};

ok((map { $_->insert_or_update } values %$objects),"Updating objects in db.");

1;
