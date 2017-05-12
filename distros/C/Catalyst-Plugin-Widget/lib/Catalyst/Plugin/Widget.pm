package Catalyst::Plugin::Widget;

=head1 NAME

Catalyst::Plugin::Widget - Simple way to create reusable HTML fragments

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

use strict;
use warnings qw(all);


=head1 DESCRIPTION

Termin I<widget> means kind of object that knows about current L<Catalyst>
context and can be easily stringified to text representation.

A typical example of a widget - L<CatalystX::Widget::Paginator> module.


=head1 SYNOPSIS

Setup plugin:

  use Catalyst( qw( Widget ) );


Create custom widget class:

  package MyApp::Widget::Greeting;
  use Moose;
  extends 'Catalyst::Plugin::Widget::Base';

  has nobody => ( is => 'rw', default => "Sorry, what's your name?" );

  sub render {
    my $self = shift;
    $self->context->can('user_exists') && $self->context->user_exists ?
        'Hello, ' . $self->context->user->name : $self->nobody;
  }

  1;


Create widget instance in controller>:

  sub index :Path :Args(0) {
      my ( $self,$c ) = @_;
      my $w = $c->widget('~Greeting');
      $c->stash( greet => $w );
  }


Place widget onto template:

  From auth: [% greet %]



=head1 METHODS

=head2 widget

Create instance of widget class.
Class name is handled by the following rules:

- starting with the '+': use the entire name (except '+' sign)

- starting with the '~': use name (except '~' sign) prepended with
application class name and '::Widget::'.

- other: use name prepended with application config parameter
$config->{ widget }{ default_namespace } or string 'CatalystX::Widget::'

Examples:

  $c->widget('+Some::Class');  # Some::Class

  $c->widget('~Class');        # App::Widget::Class

  $c->widget('Class');         # CatalystX::Widget::Class

  App->config{ widget }{ default_namespace } = 'Local';
  $c->widget('Class');         # Local::Class

=cut

sub widget {
	my ( $app,$class ) = splice @_,0,2;

	unless ( $class =~ s/^\+// ) {
		$class = ( $class =~ s/^~// ?
			ref( $app ) . '::Widget::' :
			$app->config->{ widget }{ default_namespace } ||
			'CatalystX::Widget::' ) . $class;
	}

	eval 'use ' . $class unless $app->{ __widgets__ }{ $class };
	return $app->error( "Can't create widget: " . $@ ) if $@;
	$app->{ __widgets__ }{ $class } ||= 1;

	$app->log->debug( 'Creating widget: "' . $class . '"' )
		if $app->debug;

	return $class->new( $app, @_ );
}


=head1 AUTHOR

Oleg A. Mamontov, C<< <oleg at mamontov.net> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-plugin-widget at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-Widget>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::Widget


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-Widget>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Widget>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-Widget>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-Widget/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Oleg A. Mamontov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


1;

