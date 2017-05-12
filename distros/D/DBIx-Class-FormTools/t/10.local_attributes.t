use Test::More;
use Data::Dump 'pp';

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 11);
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
my $film1 = $schema->resultset('Film')->create({
    title   => 'Office Space',
    comment => 'Funny film',
});

my $film2 = $schema->resultset('Film')->create({
    title   => 'Office Space II',
    comment => 'Really funny film',
});

my $film3 = $schema->resultset('Film')->new({
    title   => 'Kill Bill',
    comment => 'Pussy Wagon',
});

my $film4 = $schema->resultset('Film')->new({
    title   => 'Donnie Darko',
    comment => 'Watch the sky for engines',
});


# Create a form with 2 existing objects and 2 new objects
my $formdata = {
    # The existing objects
    $helper->fieldname($film1, 'title' ,  'o1') => 'Southpark',
    $helper->fieldname($film1, 'length',  'o1') => 42,
    $helper->fieldname($film1, 'comment', 'o1') => 'Damn it!',
    $helper->fieldname($film2, 'title',   'o2') => 'Pulp Fiction',
    $helper->fieldname($film2, 'length',  'o2') => 120,
    $helper->fieldname($film2, 'comment', 'o2') => "Zed's dead baby...",

    # The new objects
    $helper->fieldname($film3, 'title',     'o3') => 'Kill bill',
    $helper->fieldname($film3, 'length',    'o3') => 99,
    $helper->fieldname($film3, 'comment',   'o3') => 'Pussy wagon',
    $helper->fieldname($film4, 'title',     'o4') => 'Donnie Darko',
    $helper->fieldname($film4, 'length',    'o4') => 123,
    $helper->fieldname($film4, 'comment',   'o4') => 'Watch the sky for engines',
};
ok(1,"Formdata created:\n".pp($formdata));


# Extract all 4 objects
my @objects = $helper->formdata_to_objects($formdata);
ok(@objects == 4, 'Excacly four object retrieved');
ok(ref($objects[0]) eq 'Schema::Film', 'Object is a Film');
ok(ref($objects[1]) eq 'Schema::Film', 'Object is a Film');
ok(ref($objects[2]) eq 'Schema::Film', 'Object is a Film');
ok(ref($objects[3]) eq 'Schema::Film', 'Object is a Film');


print 'Final objects: '.pp(\@objects)
    if $ENV{DBIX_CLASS_FORMTOOLS_DEBUG};

ok((map { $_->insert_or_update } @objects),"Updating objects in db");

1;
