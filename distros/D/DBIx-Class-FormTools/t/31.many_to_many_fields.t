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
my $film = $schema->resultset('Film')->new({
    title   => 'Office Space',
    comment => 'Funny film',
});

my $actor = $schema->resultset('Actor')->new({
    name   => 'Cartman',
});

my $role = $schema->resultset('Role')->new({
#    charater => 'The New guy',
});

my $formdata = {
    # The existing objects
    $helper->fieldname($film, 'title',   'o1') => 'Black Ninja III',
    $helper->fieldname($film, 'length',  'o1') => 122,
    $helper->fieldname($film, 'comment', 'o1') => 'It is night ..',
    $helper->fieldname($role,  undef,    'o3', {
        film_id  => 'o1',
        actor_id => 'o2',
    }) => 'Dummy value',
    $helper->fieldname($actor, 'name',   'o2') => 'Chuck Norris',
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
