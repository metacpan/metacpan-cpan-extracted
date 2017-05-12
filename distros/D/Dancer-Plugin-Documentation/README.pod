package Dancer::Plugin::Documentation;

=head1 NAME

Dancer::Plugin::Documentation - register documentation for routes

=cut

use strict;
use warnings;

use Carp qw{croak};
use Scalar::Util (qw{blessed});
use Set::Functional (qw{setify_by});

use Dancer::App;
use Dancer::Plugin;
use Dancer::Plugin::Documentation::Route;
use Dancer::Plugin::Documentation::Section;

use namespace::clean;


=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Dancer::Plugin::Documentation provides a few keywords to associate documentation
with a fully pathed route.  This is especially useful when the route path is
externally modified by the prefix command.  Documentation my be anything from a
string to a complex data structure.

Example usage:

	package Foo;

	use Dancer;
	use Dancer::Plugin::Documentation qw{:all};

	document_section 'Helpers';

	document_route 'Display documentation'
	get '/resources' => sub {
		status 200;
		return join "\n\n",
			map {
				$_->isa('Dancer::Plugin::Documentation::Section') ? ($_->section, $_->documentation || ()) :
				$_->isa('Dancer::Plugin::Documentation::Route') ? ($_->method . ' ' . $_->path, $_->documentation) :
					$_->documentation
			} documentation;
	};

	prefix '/v1';

	document_section 'Foo', 'Manage your foo';

	document_route 'A route to retrieve foo',
	get '/foo' => sub { status 200; return 'foo' };

	package main;

	dance;

=cut

my %APP_TO_ACTIVE_SECTION;
my %APP_TO_ROUTE_DOCUMENTATION;
my %APP_TO_SECTION_DOCUMENTATION;

=head1 KEYWORDS

=cut

=head2 document_route

Given a documentation argument and a list of routes, associate the
documentation with all of the routes.

=cut

register document_route => sub {
	my ($documentation, @routes) = @_;

	my $app = Dancer::App->current->name;

	croak "Documentation missing, Dancer::Route found instead"
		if blessed $documentation && $documentation->isa('Dancer::Route');

	croak "Invalid argument where Dancer::Route expected"
		if grep { ! blessed $_ || ! $_->isa('Dancer::Route') } @routes;

	Dancer::Plugin::Documentation->set_route_documentation(
		app => $app,
		path => $_->pattern,
		method => $_->method,
		documentation => $documentation,
		section => Dancer::Plugin::Documentation->get_active_section(app => $app),
	) for @routes;

	return @routes;
};

=head2 document_section

Given a label, set the section grouping for all subsequent document_route calls.
Optionally, supply documentation to associate with the section.  Disable the
current section by passing undef or the empty string for the label.

=cut

register document_section => sub {
	my ($section, $documentation) = @_;

	my $app = Dancer::App->current->name;
	$section = '' unless defined $section;

	Dancer::Plugin::Documentation->set_section_documentation(
		app => $app,
		section => $section,
		documentation => $documentation,
	) unless $section eq '';
	Dancer::Plugin::Documentation->set_active_section(
		app => $app,
		section => $section,
	);

	return;
};

=head2 documentation

Retrieve all documentation for the current app with sections interweaved
with routes.  Supports all arguments for documentation_for_routes and
documentation_for_sections.

=cut

register documentation => sub {
	my %args = @_;
	my @route_documentation = documentation_for_routes(%args);
	my @section_documentation =
		! keys %args || exists $args{section}
		? documentation_for_sections(%args)
		: ();

	my @documentation;
	while (@section_documentation && @route_documentation) {
		push @documentation, $section_documentation[0]->section le $route_documentation[0]->section
			? shift @section_documentation
			: shift @route_documentation
			;
	}
	push @documentation, @section_documentation;
	push @documentation, @route_documentation;

	return @documentation;
};

=head2 documentation_for_routes

Retrieve all route documentation for the current app.  Supports all the same
arguments as get_route_documentation besides app.

=cut

register documentation_for_routes => sub {
	return Dancer::Plugin::Documentation->get_route_documentation(
		@_,
		app => Dancer::App->current->name,
	);
};

=head2 documentation_for_sections

Retrieve all section documentation for the current app.  Supports all the same
arguments as get_section_documentation besides app.

=cut

register documentation_for_sections => sub {
	my %args = @_;

	return Dancer::Plugin::Documentation->get_section_documentation(
		@_,
		app => Dancer::App->current->name,
	);
};

=head1 DOCUMENTATION METHODS

=head2 get_route_documentation

Retrieve the route documentation for an app in lexicographical order by
section, route, then method.  Any/all of the following may be supplied to
filter the documentation: method, path, section

=cut

sub get_route_documentation {
	my ($class, %args) = @_;

	defined $args{$_} || croak "Argument [$_] is required"
		for qw{ app };

	my ($app, $method, $path, $section) = @args{qw{app method path section}};
	$method = lc $method if $method;
	$section = lc $section if $section;

	my @docs = @{$APP_TO_ROUTE_DOCUMENTATION{$app} || []};

	@docs = grep { $_->section eq $section } @docs if defined $section;
	@docs = grep { $_->path eq $path } @docs if defined $path;
	@docs = grep { $_->method eq $method } @docs if defined $method;

	return @docs;
}

=head2 get_section_documentation

Retrieve the section documentation for an app in lexicographical order.
Any/all of the following may be supplied to filter the documentation: section

=cut

sub get_section_documentation {
	my ($class, %args) = @_;

	defined $args{$_} || croak "Argument [$_] is required"
		for qw{ app };

	my ($app, $section) = @args{qw{app section}};
	$section = lc $section if $section;

	my @docs = @{$APP_TO_SECTION_DOCUMENTATION{$app} || []};

	@docs = grep { $_->section eq $section } @docs if defined $section;

	return @docs;
}

=head2 set_route_documentation

Register documentation for the method and route of a particular app.

=cut

sub set_route_documentation {
	my $class = shift;

	my $route_documentation = Dancer::Plugin::Documentation::Route->new(@_);

	#We take the hit to keep all documentation in a sorted unique list on insertion
	#so that any retrieval requests are highly optimized.
	$APP_TO_ROUTE_DOCUMENTATION{$route_documentation->app} = [
		sort { 0
			|| $a->section cmp $b->section
			|| $a->path cmp $b->path
			|| $a->method cmp $b->method
		}
		setify_by { $_->method . ':' . $_->path }
		(
			@{$APP_TO_ROUTE_DOCUMENTATION{$route_documentation->app} || []},
			$route_documentation,
		)
	];

	return $class;
}

=head2 set_section_documentation

Register documentation for the section of a particular app.

=cut

sub set_section_documentation {
	my $class = shift;

	my $section_documentation = Dancer::Plugin::Documentation::Section->new(@_);

	#We take the hit to keep all documentation in a sorted unique list on insertion
	#so that any retrieval requests are highly optimized.
	$APP_TO_SECTION_DOCUMENTATION{$section_documentation->app} = [
		sort { $a->section cmp $b->section }
		setify_by { $_->section }
		(
			@{$APP_TO_SECTION_DOCUMENTATION{$section_documentation->app} || []},
			$section_documentation,
		)
	];

	return $class;
}

=head1 APPLICATION STATE METHODS

=cut

=head2 get_active_section

Get the name of the active section for the application.

=cut

sub get_active_section {
	my ($class, %args) = @_;

	defined $args{$_} || croak "Argument [$_] is required"
		for qw{ app };

	my ($app) = @args{qw{ app }};

	return $APP_TO_ACTIVE_SECTION{$app} || '';
}

=head2 set_active_section

Set the name of the active section for the application.

=cut

sub set_active_section {
	my ($class, %args) = @_;

	defined $args{$_} || croak "Argument [$_] is required"
		for qw{ app section };

	my ($app, $section) = @args{qw{ app section }};
	$APP_TO_ACTIVE_SECTION{$app} = $section;

	return $class;
}

=head1 CAVEATS

=over 4

=item any

The documentation keyword does not work with the I<any> keyword as it does not
return the list of registered routes, but rather the number of routes
registered.  Fixing this behavior will require a patch to Dancer.

=item get

The I<get> keyword generates both get and head routes.  Documentation will be
attached to both.

=back

=head1 AUTHOR

Aaron Cohen, C<< <aarondcohen at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

This module was made possible by L<Shutterstock|http://www.shutterstock.com/>
(L<@ShutterTech|https://twitter.com/ShutterTech>).  Additional open source
projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-Dancer-Plugin-Documentation at rt.cpan.org>, or through
the web interface at L<https://github.com/aarondcohen/perl-dancer-plugin-documentation/issues>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Documentation

You can also look for information at:

=over 4

=item * Official GitHub Repo

L<https://github.com/aarondcohen/perl-dancer-plugin-documentation>

=item * GitHub's Issue Tracker (report bugs here)

L<https://github.com/aarondcohen/perl-dancer-plugin-documentation/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Documentation>

=item * Official CPAN Page

L<http://search.cpan.org/dist/Dancer-Plugin-Documentation/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Aaron Cohen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

register_plugin;
1; # End of Dancer::Plugin::Documentation
