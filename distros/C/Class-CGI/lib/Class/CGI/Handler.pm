package Class::CGI::Handler;

use strict;
use warnings;

=head1 NAME

Class::CGI::Handler - Base class for Class::CGI handlers

=head1 VERSION

Version 0.20

=cut

our $VERSION = '0.20';

=head1 SYNOPSIS

    use base 'Class::CGI::Handler';

    sub handle {
        my $self  = shift;
        my $cgi   = $self->cgi;
        my $param = $self->param;
        # validate stuff and return anything you want
    }

=head1 DESCRIPTION

Handlers for C<Class::CGI> should inherit from this class.  This class
provides a constructor which builds the handler object and checks to see if
the param value from the CGI data is required.  If so, it will automatically
set a "missing" error if the parameter is not present.  See the L<has_param>
method for more details.

=cut

##############################################################################

=head1 Methods

=head2 new

  my $handler = Some::Handler::Subclass->new( $cgi, $param );

Returns a new handler object.  Returns nothing if the parameter is required
but not present.

=cut

sub new {
    my ( $class, $cgi, $param ) = @_;
    my $self = bless {
        cgi   => $cgi,
        param => $param,
    }, $class;
    if ( $cgi->is_required($param) ) {
        return unless $self->has_param;
    }
    return $self->handle;
}

##############################################################################

=head2 has_param 

  if ( $handler->has_param ) {
      ...
  }

Returns a boolean value indicating whether or not the current parameter was
found in the form.  If a parameter is "real", that is to say, the requested
parameter name and the actual parameter name are identical, then this method
should be all you need.  For example:

In the HTML:

 <input type="text" name="age"/>

In the code:

 my $age = $cgi->param('age');

If the parameter is "virtual" (the requested parameter name does not match the
name in the HTML), then this method should be overridden in your subclass.

Note that the this method will automatically report the parameter as "missing"
to the C<Class::CGI> object if it's a required parameter.

=cut

sub has_param {
    my $self  = shift;
    my $param = $self->param;
    return 1 unless $self->_missing($param);
    $self->cgi->add_missing($param);
    return;
}

##############################################################################

=head2 has_virtual_param

  if ( $cgi->has_virtual_param( $param, @list_of_parameters ) ) {
  }

Very similar to the C<has_param> method.  However, instead of checking to see
if the current parameter exists, you pass in the name of the virtual parameter
and a list of the component parameters which comprise the virtual parameter.
For example:

  if ( $handler->has_virtual_param( 'date', qw/day month year/ ) ) {
      ....
  }

Note that the this method will automatically report the parameter as "missing"
to the C<Class::CGI> object if it's a required parameter.

=cut

sub has_virtual_param {
    my ( $self, $param, @components ) = @_;
    if ( my %missing = $self->_missing(@components) ) {
        my @missing = grep { exists $missing{$_} } @components;
        $self->cgi->add_missing(
            $param,
            "The '$param' is missing values for (@missing)"
        );
        return;
    }
    return 1;
}

##############################################################################

=head2 handle

  return $handler->handle;

This method must be overridden in a subclass.  It is the primary method used
to actually validate and optionally untaint form data and return the
appropriate data.  See C<WRITING HANDLERS> in the L<Class::CGI> documentation.

=cut

sub handle {
    require Carp;
    Carp::croak("You must override the Class::CGI::handle() method");
}

##############################################################################

=head2 cgi

  my $cgi = $handler->cgi;

Returns the C<Class::CGI> object used to call the handler.

=cut

sub cgi { shift->{cgi} }

##############################################################################

=head2 param

  my $param = $cgi->param;

Returns the parameter name the user has requested.

=cut

sub param { shift->{param} }

##############################################################################

=head2 _missing

  if ( my %missing = $handler->_missing(@params) ) {
     ...
  }

This is a protected method which should only be called by subclasses.

Given a list of parameter names (actual, not virtual), this method will return
a hash of all parameters whose value is undefined or the empty string.  The
keys are the parameter names and the values are the value received from the
C<Class::CGI> object.

=cut

sub _missing {
    my ( $self, @params ) = @_;
    my $cgi     = $self->cgi;
    my %missing =
      map { $_->[0], $_->[1] }  # prevent the "odd number of elements" warning
      grep { !defined $_->[1] || '' eq $_->[1] }
      map { [ $_, $cgi->raw_param($_) ] } @params;
    return %missing;
}

=head1 TODO

This module should be considered alpha code.  It probably has bugs.  Comments
and suggestions welcome.

The only current "TODO" is to allow overridding error messages.

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid@cpan.org> >>

=head1 SUPPORT

There is a mailing list at L<http://groups.yahoo.com/group/class_cgi/>.
Currently it is low volume.  That might change in the future.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-cgi@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-CGI>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

If you are unsure if a particular behavior is a bug, feel free to send mail to
the mailing list.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
