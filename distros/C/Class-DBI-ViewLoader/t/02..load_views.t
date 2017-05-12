use strict;
use warnings;

use Test::More tests => 27;

# load testing modules
use lib qw( t/lib );
require Class::DBI::NullPlugin;
require Class::DBI::MockPlugin;
require Class::DBI::NullBase;

BEGIN {
    use_ok('Class::DBI::ViewLoader');
}

unless (exists $Class::DBI::ViewLoader::handlers{'Mock'}) {
    # Module::Pluggable doesn't look in non-blib dirs under -Mblib
    require Class::DBI::ViewLoader::Mock;
    $Class::DBI::ViewLoader::handlers{'Mock'} = 'Class::DBI::ViewLoader::Mock';
}

my(@views, $loader);
my %args = (
	dsn => 'dbi:Mock:whatever',
	username => 'me',
	password => 'mypass',
    );

{
    # set up a base class with a connection to inherit
    no strict 'refs';
    @{"MyBase\::ISA"} = qw( Class::DBI );
    MyBase->connection('dbi:Mock:');
}

$loader = new Class::DBI::ViewLoader (
	%args,
	namespace => 'MyClass',
        base_classes => 'MyBase',
    );

@views = $loader->load_views;
is(@views, 2, 'Loaded 2 views');
is($views[0], 'MyClass::TestView', 'created class MyClass::TestView');
is($views[1], 'MyClass::ViewTwo',  'created class MyClass::TestView');

# default column accessors
can_ok('MyClass::TestView', qw( foo bar baz ));

# isa_ok doesn't work on non-refs
ok($views[0]->isa('Class::DBI::Mock'), "$views[0] isa Class::DBI::Mock");
ok($views[1]->isa('Class::DBI::Mock'), "$views[1] isa Class::DBI::Mock");

my $parent_dbh = MyBase->db_Main;
is($views[0]->db_Main, $parent_dbh, "$views[0] inherited db_Main");
is($views[1]->db_Main, $parent_dbh, "$views[1] inherited db_Main");

is($loader->load_views, 0, 'Attempt to reload classes fails.');

# Be sure to change namespace too, so we don't try and reload existing classes
$loader->set_exclude(qr(^test_))->set_namespace('MyClassA');
$loader->set_accessor_prefix('get_')->set_mutator_prefix('set_');
@views = $loader->load_views;
is(@views, 1, 'load_views with exclude rule');
is($views[0], 'MyClassA::ViewTwo', '  returns as expected');
$loader->set_exclude();

$loader->set_include(qr(^test_));
@views = $loader->load_views;
is(@views, 1, 'load_views with include rule');
is($views[0], 'MyClassA::TestView', '  returns as expected');
$loader->set_include();

# custom accessors
can_ok('MyClassA::TestView', map { ("get_$_", "set_$_") } qw( foo bar baz));

$loader = new Class::DBI::ViewLoader (
	%args,
	namespace => 'ImportTest',
	import_classes => [qw/
	    Class::DBI::NullPlugin
	    Class::DBI::MockPlugin
	/]
    );

@views = $loader->load_views;
can_ok($views[0], 'null');
{
    no strict 'refs';
    ok(${$views[0].'::MockPluginLoaded'}, "non-Exporter import worked");
}

$loader->set_base_classes(qw(Class::DBI::NullBase))->set_namespace('BaseTest');

@views = $loader->load_views;
ok($views[0]->isa('Class::DBI::NullBase'), "$views[0] isa Class::DBI::NullBase");

is($loader->view_to_class,     '', "view_to_class(undef) is ''");
is($loader->view_to_class(''), '', "view_to_class('') is ''");
$loader->set_namespace("NamingTest");
is($loader->view_to_class('my_view'), 'NamingTest::MyView', 'view_to_class("my_view") as expected');

# test for boolean bug

my $i = MyClass::TestView->retrieve_all;
isa_ok($i, 'Class::DBI::Iterator');
is($i->count, 3, 'got 3 rows');
for my $j (1 .. 2) {
    my $row = $i->next;
    ok($row, "row $j is true");
}

# last row should be false
ok(!$i->next, "row 3 is false");

# Check non-inherited dbh setup

$loader = new Class::DBI::ViewLoader (
        dsn => 'dbi:Mock:',
        namespace => 'MyDB',
    );

@views = $loader->load_views();
is($views[0]->db_Main, $views[1]->db_Main,
        "Loaded views share a handle without inheritance");

__END__

vim: ft=perl
