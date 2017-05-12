use Test::More;
use Data::Dump 'pp';

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 10);
}

INIT {
    use lib 't/lib';
    use Film;
}

ok(Film->can('db_Main'), 'set_db()');
is(Film->__driver, "SQLite", "Driver set correctly");

# Create 2 test objects
my $film1 = Film->create_test_object;
my $film2 = Film->create_test_object;

my $field_definition = qr{
    cdbi    # Prefix
    \|      # Seperator
    [\w]+  # Object id
    \|      # Seperator
    [\w:]+  # Classname
    \|      # Seperator
    \d+     # Id field
    \|      # Seperator
    \w*     # Attribute name (optional)
}x;

# Validate that the fields match the definition
like($film1->form_fieldname('title','o1'),   $field_definition,
     "form_fieldname: " . $film1->form_fieldname('title','o1'));
like($film1->form_fieldname('length','o1'),  $field_definition,
     "form_fieldname: " . $film1->form_fieldname('length','o1'));
like($film1->form_fieldname('comment','o1'), $field_definition,
     "form_fieldname: " . $film1->form_fieldname('comment','o1'));

# Validate html creation method
ok($film1->form_field('title','text','o1'),
   "formfield: ".$film1->form_field('title','text','o1'));
ok($film1->form_field('length','text','o1'),
   "formfield: ".$film1->form_field('length','text','o1'));
ok($film1->form_field('comment','text','o1'),
   "formfield: ".$film1->form_field('comment','text','o1'));

#print $film1->form_field('title','checkbox');
#ok('Checkbox field working');

#print $film1->form_field('title','radio');
#ok('Radio field working');


# Create a form with 2 existing objects and 2 new objects
my $formdata = {
    # The existing objects
    $film1->form_fieldname('title' ,  'o1') => 'Title',
    $film1->form_fieldname('length',  'o1') => 99,
    $film1->form_fieldname('comment', 'o1') => 'This is a comment',
    $film2->form_fieldname('title',   'o2') => 'Title',
    $film2->form_fieldname('length',  'o2') => 99,
    $film2->form_fieldname('comment', 'o2') => 'This is a comment',

    # The new objects
    Film->form_fieldname('title',     'o3') => 'Title',
    Film->form_fieldname('length',    'o3') => 99,
    Film->form_fieldname('comment',   'o3') => 'This is a comment',
    Film->form_fieldname('title',     'o4') => 'Title',
    Film->form_fieldname('length',    'o4') => 99,
    Film->form_fieldname('comment',   'o4') => 'This is a comment',
};
print 'Formdata: '.pp($formdata)."\n";

# Extract all 4 objects
my @objects = Class::DBI::FormTools->formdata_to_objects($formdata);
ok(
    (grep { ref($_) eq 'Film' } @objects) == 4,
    "formdata_to_objects: Ojects extracted " . pp(\@objects)
);

# Update objects
foreach my $object ( @objects ) {
    $object->update || diag("Unable to update object $object");
}
ok(1,"Objects updated");


