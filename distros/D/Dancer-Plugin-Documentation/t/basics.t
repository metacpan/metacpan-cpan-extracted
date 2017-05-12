#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/lib";

use List::Util ();
use Test::Most tests => 45;

use Dancer::Plugin::Documentation;

my $class = 'Dancer::Plugin::Documentation';
my $id = time + 100000;

sub unique_id() { ++$id }
sub create_app() { 'new_app:' . unique_id }
sub create_section() { 'new_section:' . unique_id }

sub create_route_args { (app => create_app, method => 'get', path => '/foo', @_) }
sub create_section_args { (app => create_app, section => create_section, @_) }

sub check_required {
	my ($function_name, $error_pattern, $required_to_valid) = @_;

	my @required_args = sort keys %$required_to_valid;

	for my $arg (@required_args) {
		my $pattern = sprintf($error_pattern, $arg);
		my %args = %$required_to_valid;

		$args{$arg} = undef;
		throws_ok
			{ $class->$function_name(%args) }
			qr{$pattern},
			"$function_name fails with undefined parameter $arg";

		delete $args{$arg};
		throws_ok
			{ $class->$function_name(%args) }
			qr{$pattern},
			"$function_name fails without parameter $arg";
	}

	lives_ok
		{ $class->$function_name(%$required_to_valid) }
		"$function_name succeeds with all parameters";
}

#########################
# Tests
#########################

sub test_required_arguments {
	check_required(get_active_section => 'Argument \\[%s\\] is required\\b', {app => 'myapp'});
	check_required(get_route_documentation => 'Argument \\[%s\\] is required\\b', {app => 'myapp'});
	check_required(get_section_documentation => 'Argument \\[%s\\] is required\\b', {app => 'myapp'});
	check_required(set_active_section => 'Argument \\[%s\\] is required\\b', {app => 'myapp', section => 'Foo'});
	check_required(set_route_documentation => 'isa check for "%s" failed', {app => 'myapp', method => 'get', path => '/foo'});
	check_required(set_section_documentation => 'isa check for "%s" failed', {app => 'myapp', section => 'Foo'});
}

sub test_overwriting_active_section {
	my $app = create_app;
	my ($first_section, $second_section);
	my %default_args = create_section_args(app => $app);

	$class->set_active_section(app => $app, section => ($first_section = create_section));
	is $class->get_active_section(app => $app), $first_section;
	$class->set_active_section(app => $app, section => ($second_section = create_section));
	is $class->get_active_section(app => $app), $second_section;
	isnt $first_section, $second_section;
}

sub test_overwriting_route_documentation {
	my %default_args = create_route_args;

	$class->set_route_documentation(%default_args, documentation => 'some value');
	is_deeply
		[$class->get_route_documentation(%default_args)],
		[Dancer::Plugin::Documentation::Route->new(%default_args, documentation => 'some value')];

	$class->set_route_documentation(%default_args, documentation => 'a different value');
	is_deeply
		[$class->get_route_documentation(%default_args)],
		[Dancer::Plugin::Documentation::Route->new(%default_args, documentation => 'a different value')];
}

sub test_overwriting_section_documentation {
	my %default_args = create_section_args;

	$class->set_section_documentation(%default_args, documentation => 'some value');
	is_deeply
		[$class->get_section_documentation(%default_args)],
		[Dancer::Plugin::Documentation::Section->new(%default_args, documentation => 'some value')];

	$class->set_section_documentation(%default_args, documentation => 'a different value');
	is_deeply
		[$class->get_section_documentation(%default_args)],
		[Dancer::Plugin::Documentation::Section->new(%default_args, documentation => 'a different value')];
}

sub test_retrieving_route_documentation {
	my $app = create_app;
	my %default_args = create_route_args(app => $app);
	my @routes = map { +{%default_args, %$_} } (
		{path => '/something/1'},
		{path => '/something/10'},
		{path => '/something/10', method => 'post'},
		{path => '/something/10', method => 'put'},
		{path => '/something/2'},
		{path => '/before', method => 'delete', section => 'earlier'},
		{path => '/before/you', method => 'delete', section => 'earlier'},
		{path => '/after', method => 'delete', section => 'later'},
		{path => '/after', section => 'later'},
	);

	is_deeply
		[$class->get_route_documentation(app => $app)],
		[],
		'get_route_documentation returns the empty list when no routes are registered';

	$class->set_route_documentation(%$_) for List::Util::shuffle @routes;

	is_deeply
		[$class->get_route_documentation(app => $app)],
		[map { Dancer::Plugin::Documentation::Route->new(%$_) } @routes],
		'get_route_documentation orders by section -> path -> method';

	is_deeply
		[$class->get_route_documentation(app => $app, method => 'delete')],
		[map { Dancer::Plugin::Documentation::Route->new(%$_) } @routes[5,6,7]],
		'get_route_documentation can extract by method';

	is_deeply
		[$class->get_route_documentation(app => $app, method => 'DeLeTe')],
		[map { Dancer::Plugin::Documentation::Route->new(%$_) } @routes[5,6,7]],
		'get_route_documentation can extract by method case-insensitively';

	is_deeply
		[$class->get_route_documentation(app => $app, path => '/something/10')],
		[map { Dancer::Plugin::Documentation::Route->new(%$_) } @routes[1,2,3]],
		'get_route_documentation can extract by path';

	is_deeply
		[$class->get_route_documentation(app => $app, section => 'earlier')],
		[map { Dancer::Plugin::Documentation::Route->new(%$_) } @routes[5,6]],
		'get_route_documentation can extract by section';

	is_deeply
		[$class->get_route_documentation(app => $app, section => 'EaRliEr')],
		[map { Dancer::Plugin::Documentation::Route->new(%$_) } @routes[5,6]],
		'get_route_documentation can extract by section case-insensitively';

	is_deeply
		[$class->get_route_documentation(app => $app, section => 'later', method => 'get', path => '/after')],
		[map { Dancer::Plugin::Documentation::Route->new(%$_) } $routes[8]];
		'get_route_documentation can extract by multiple methods simultaneously';
}

sub test_registering_section_documentation {
	my $app = create_app;
	my %default_args = create_section_args(app => $app);
	my @sections = map { +{%default_args, %$_} } (
		{section => 'first'},
		{section => 'second'},
		{section => 'third'},
	);

	is_deeply
		[$class->get_section_documentation(app => $app)],
		[],
		'get_section_documentation returns the empty list when no sections are registered';

	$class->set_section_documentation(%$_) for List::Util::shuffle @sections;

	is_deeply
		[$class->get_section_documentation(app => $app)],
		[map { Dancer::Plugin::Documentation::Section->new(%$_) } @sections],
		'get_section_documentation orders by section';

	is_deeply
		[$class->get_section_documentation(app => $app, section => 'second')],
		[map { Dancer::Plugin::Documentation::Section->new(%$_) } $sections[1]],
		'get_section_documentation can extract by section';

	is_deeply
		[$class->get_section_documentation(app => $app, section => 'SeCoNd')],
		[map { Dancer::Plugin::Documentation::Section->new(%$_) } $sections[1]],
		'get_section_documentation can extract by section case-insensitively';
}

#$class->set_route_documentation(default_args, app => 'caseapp', method => 'GET', path => '/bar');
#is_deeply
#	[$class->get_route_documentation(app => 'caseapp')],
#	[{documentation => 'some docs', method => 'get', path => '/bar'}],
#	'methods are stored in lowercase';


for my $test (sort grep { $_ =~ /^test_/ } keys %{main::}) {
	do {
		local $\ = "\n";
		local $, = " ";
		print '#', split /_/, $test;
	};
	do { no strict 'refs'; &$test };
}
