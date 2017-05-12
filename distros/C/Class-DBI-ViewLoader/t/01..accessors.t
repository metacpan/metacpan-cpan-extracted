use strict;
use warnings;

use Test::More tests => 71;

use lib qw( t/lib );

BEGIN {
    use_ok('Class::DBI::ViewLoader');
}

unless (exists $Class::DBI::ViewLoader::handlers{'Mock'}) {
    # Module::Pluggable doesn't look in non-blib dirs under -Mblib
    require Class::DBI::ViewLoader::Mock;
    $Class::DBI::ViewLoader::handlers{'Mock'} = 'Class::DBI::ViewLoader::Mock';
}

# simple args for new()
my %args = (
	dsn => 'dbi:Mock:whatever',
	username => 'me',
	password => 'mypass',
	namespace => 'MyClass',
        accessor_prefix => 'get_',
        mutator_prefix => 'set_',
    );

my $loader = new Class::DBI::ViewLoader (
	%args,
	include => '',
	exclude => '',
	options => {}
    );

isa_ok($loader, 'Class::DBI::ViewLoader', '$loader');
for my $field (keys %args) {
    my $meth = "get_$field";
    is($loader->$meth, $args{$field}, "\$loader->$meth");
}

$loader = new Class::DBI::ViewLoader;
for my $field (keys %args) {
    my $setter = "set_$field";
    my $getter = "get_$field";
    is($loader->$setter($args{$field}), $loader, "$setter returns the object");
    is($loader->$getter, $args{$field},          "$getter returns the value");
}

# non-simple fields:

my $current_opts = $loader->get_options;
$current_opts->{'RaiseError'} = 1;
is($loader->get_options->{'RaiseError'}, 1, 'get_options on new object returns active hashref');
my $opt = { RaiseError => 1 };
is($loader->set_options($opt), $loader, "set_options returns the object");
is($loader->set_options(%$opt), $loader, "set_options works with a raw hash");
my $ref = $loader->get_options;
is($ref->{RaiseError}, 1, "get_options returns a reference");
$ref->{AutoCommit} = 1;
is($loader->get_options->{AutoCommit}, 1, "Changing the reference changes the object");

# regex field tests
for my $regex_type (qw(include exclude)) {
    my $setter = "set_$regex_type";
    my $getter = "get_$regex_type";
    my $re = '^te(?:st|mp)_';
    is($loader->$setter($re), $loader, "$setter returns the object");
    is($loader->$getter, qr($re), "$getter returns a regex"); 
    is($loader->$setter(), $loader, "$setter with no args succeeds");
    is($loader->$getter, undef, "now $getter returns undef");
}

my @ns;
$loader = new Class::DBI::ViewLoader;
@ns = $loader->get_namespace;
is(@ns, 0, 'get_namespace without a namespace returns empty list');
$loader->set_namespace('');
@ns = $loader->get_namespace;
is(@ns, 0, 'get_namespace with a \'\' namespace returns empty list');

# import/base class tests
for my $type (qw(import base left_base)) {
    my @test_list = qw(X Y Z);

    for my $class (@test_list) {
	no strict 'refs';
	@{$class.'::ISA'} = qw( Exporter );
    }

    my $setter = "set_${type}_classes";
    my $adder  = "add_${type}_classes";
    my $getter = "get_${type}_classes";

    my @initial = $loader->$getter;
    is(@initial, 0, "$getter returns empty list");
    is($loader->$setter(@test_list), $loader, "$setter returned object");
    is($loader->$getter, @test_list, "$getter got right number of classes");
    is($loader->$adder('Foo'), $loader, "$adder returned object");
    is($loader->$getter, @test_list + 1, "added test_list class");

    # check arrayrefs too
    is($loader->$setter(\@test_list), $loader, "$setter works on array ref");
    is($loader->$getter, @test_list, "$getter got an array");
}

# Class::DBI::Loader compatiblity tests
$loader = eval {
    new Class::DBI::ViewLoader (
	    debug => 1,
	    dsn => 'dbi:Mock:ignored',
	    user => 'root',
	    password => '',
	    namespace => 'CDBI::Loader::Compat',
	    additional_classes => q(Class::DBI::AbstractSearch),
	    additional_base_classes => q(My::Stuff),
            left_base_classes => [ qw(Left::One Left::Two) ],
	    constraint => '^foo.*',
	    exclude => '^bar.*',
	    relationships => 1,
	);
};
ok(!$@, 'new() with Class::DBI::Loader args lives');

# Let following tests fail but not die when the above fails
$loader = new Class::DBI::ViewLoader unless defined $loader;

is($loader->get_include(), qr(^foo.*), "get_include gets constraint");
is($loader->get_exclude(), qr(^bar.*), "get_exclude gets exclude");

my @classes;
@classes = $loader->get_import_classes;
is(@classes, 1, 'get_import_classes gets 1 class');
is($classes[0], 'Class::DBI::AbstractSearch', 'get_import_classes gets additional_classes');

@classes = $loader->_get_all_base_classes;
is(@classes, 4, 'get_base_classes gets 1 class');
is($classes[0], 'Left::Two', "get_base_classes gets additional_base_classes");
is($classes[1], 'Left::One', "get_base_classes gets additional_base_classes");
is($classes[2], $loader->base_class, "get_base_classes gets additional_base_classes");
is($classes[3], 'My::Stuff', "get_base_classes gets additional_base_classes");

is($loader->get_username, "root", "get_username returns user");

$loader = new Class::DBI::ViewLoader (
        dsn => 'dbi:Mock:',
        left_base_classes => 'Left', # Not a ref this time :-)
        base_classes => 'Right',
    );

@classes = $loader->_get_all_base_classes;
is(@classes, 3,          'new() with 1 left base class and 1 other base class');
is($classes[0], 'Left',  'left base class comes first');
is($classes[1], $loader->base_class, 'driver base_class in the middle');
is($classes[2], 'Right', 'other base class comes last')

__END__

vim: ft=perl
