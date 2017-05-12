use Test::More;
use Data::Dump 'pp';

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 12);
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

my $location = $schema->resultset('Location')->new({
    name    => 'Initec',
});

my $director = $schema->resultset('Director')->new({
    name    => 'Mr. Bigshot Movieman',
});


### Create a form with 1 existing objects with one non existing releation
my $formdata = {
    # The existing objects
    $helper->fieldname($film, 'title',       'o1') => 'Office Space - Behind the office',
    $helper->fieldname($film, 'length',      'o1') => 42,
    $helper->fieldname($film, 'comment',     'o1') => 'Short film about ...',
    $helper->fieldname($film, 'location',    'o1') => 'o2',
    $helper->fieldname($location, 'name',    'o2') => 'Initec HQ',
    $helper->fieldname($film, 'director_id', 'o1') => 'o3',
    $helper->fieldname($director, 'name',    'o3') => 'Bigshot Movieman',
};
ok(1,"Formdata created:\n".pp($formdata));

my $objects = $helper->formdata_to_object_hash($formdata);
ok(keys %$objects == 3, 'Exactly three object retrieved');
isa_ok($objects->{o1}, 'Schema::Film', 'Object is a Film.');
isa_ok($objects->{o2}, 'Schema::Location', 'Object is a Location.');
isa_ok($objects->{o3}, 'Schema::Director', 'Object is a Director.');
isa_ok($objects->{o1}->location, 'Schema::Location', 'Film has a Location.');
isa_ok($objects->{o1}->director_id, 'Schema::Director', 'Film has a Director.');

print 'Final objects: '.pp($objects) ."\n"
    if $ENV{DBIX_CLASS_FORMTOOLS_DEBUG};

ok((map { $_->insert_or_update } values %$objects),"Updating objects in db.");

1;
