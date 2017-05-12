use Test::More;
use Data::Dump 'pp';

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 4);
}

INIT {
    use lib 't/lib';
    use Location;
    use Film;
}

ok(Film->can('db_Main'), 'set_db()');
is(Film->__driver, "SQLite", "Driver set correctly");

# Create test objects
my $film = Film->create_test_object;

### Create a form with 1 existing objects with one non existing releation
my $formdata = {
    # The existing objects
    $film->form_fieldname('title',       'o1') => 'Title',
    $film->form_fieldname('length',      'o1') => 99,
    $film->form_fieldname('comment',     'o1') => 'This is a comment',
    $film->form_fieldname('location_id', 'o1') => 'o2',
    Location->form_fieldname('name',     'o2') => 'Somewhere',
};
print 'Formdata: '.pp($formdata)."\n";

my @objects = Class::DBI::FormTools->formdata_to_objects($formdata);
ok(@objects == 2,
   "formdata_to_objects: Existing object with existing relation")
        || diag(pp(\@objects));

print 'Final objects: '.pp(\@objects)."\n";

ok(map { $_->update } @objects);

