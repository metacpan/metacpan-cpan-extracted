use strict;     
use Test::More tests => 14;
use Test::Exception;

use_ok('Catalyst::Enzyme::CRUD::Model');


ok(my $model = Catalyst::Enzyme::CRUD::Model->new, "new");



print "\n* default_column_moniker\n";

is($model->default_column_moniker("foo"), "Foo", "Single word lowercase");
is($model->default_column_moniker("FOO"), "Foo", "Single word uppercase");
is($model->default_column_moniker("Foo"), "Foo", "Single word ucfirst");


is($model->default_column_moniker("id_foo"), "Foo", "Single word with id_");
is($model->default_column_moniker("foo_id"), "Foo", "Single word with _id");
is($model->default_column_moniker("id_foo_id"), "Foo", "Single word with id_ _id");
#found bug

is($model->default_column_moniker("foo_bar"), "Foo Bar", "Two word");
is($model->default_column_moniker("foo bar"), "Foo Bar", "Two word with whitespace");

is($model->default_column_moniker("foo__bar"), "Foo Bar", "Two word multi _");

is($model->default_column_moniker("foo _ _bar"), "Foo Bar", "Two word multi _ and space");


is($model->default_column_moniker("foo_Bar_BAZ"), "Foo Bar Baz", "Three word multicase");
#found bug

is($model->default_column_moniker("FOO_bar_BAZ_florp"), "Foo Bar Baz Florp", "Four word multicase");



__END__
