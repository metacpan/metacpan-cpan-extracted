package Class::CGI::DateTime;

use base 'Class::CGI::Handler';

use warnings;
use strict;
use DateTime;

=head1 NAME

Class::CGI::DateTime - Fetch DateTime objects directly from your forms.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  use Class::CGI
    handlers => {
        date       => 'Class::CGI::DateTime',
        order_date => 'Class::CGI::DateTime',
    };
  my $cgi        = Class::CGI->new;
  my $date       = $cgi->param('date');
  my $order_date = $cgi->param('order_date');

  if ( my %errors = $cgi->errors ) { ... }

=head1 DESCRIPTION

A common problem with Web programming is handling dates correctly.  This
C<Class::CGI> handler attempts to do that for you in a standard way by
allowing you to have separate day, month and year dropdowns but request a
"date" parameter and get the correct object back, safely validated and
untainted.

Multiple dates may be used in a single form and you can even specify hours,
minutes, timezones, and so on.

=head2 Basic Usage

If you have a form with C<< <select> >> boxes named C<day>, C<month> and
C<year>, you can fetch these into a C<DateTime> object with this:

  use Class::CGI
    handlers => {
        date => 'Class::CGI::DateTime',
    };
  my $cgi        = Class::CGI->new;
  my $date       = $cgi->param('date');

The value of each parameter should correspond to allowed values for that
parameter to the C<DateTime> constructor.

=head2 Multiple dates in a form

If you need more than one date object embedded in a form, additional date
objects may be specified by prefixing the form parameter names with a unique
identifier followed by a dot (".").  For example, to fetch a date and an order
date, you can do the following:

  use Class::CGI
    handlers => {
        date       => 'Class::CGI::DateTime',
        order_date => 'Class::CGI::DateTime',
    };
  my $cgi        = Class::CGI->new;
  my $date       = $cgi->param('date');
  my $order_date = $cgi->param('order_date');

The C<date> parameter will be created from the C<day>, C<month> and C<year>
parameters in the C<Class::CGI> object.  The C<order_date.date> parameter will
be created from the C<order_date.day>, C<order_date.month> and
C<order_date.year> parameters.

=head2 Different parameters

 $cgi->args( date => { params => [qw/ day hour minute /] } );

You cannot change the parameter names (e.g., no changing "day" to "jour" or
something like that), but you can specify additional parameters which the
C<DateTime> constructor expects.  Each parameter's value must correspond to
the allowed values for the C<DateTime> object.  You do this by setting the
requested parameters in C<Class::CGI>'s C<args()> method.  The key is the date
parameter you wish to specify the arguments for and the value should be a
hashref with a key of "params" and a value being an array reference specifying
the names of the parameters desired.

For example, if your HTML form has day, month, year and timezone, you might do
this:

  use Class::CGI
    handlers => {
        date => 'Class::CGI::DateTime',
    };
  my $cgi        = Class::CGI->new;
  $cgi->args( 
     date => { params => [qw/ day month year time_zone /] }
  );
  my $date       = $cgi->param('date');

The allowed parameter names, as specified from the C<DateTime> documentation,
are:

=over 4

=item * year

=item * month

=item * day

=item * hour

=item * minute

=item * second

=item * nanosecond

=item * time_zone

=back

=head2 Error handling

As usual, any errors reported by C<Class::CGI::DateTime> will be in the
C<Class::CGI> C<errors()> method.  However, the validation errors reported by
the C<DateTime> object are generally aimed at programmers, not users of your
software.  Thus, you'll want to provide more user friendly error messages.
For example:

  if ( my %error_for = $cgi->errors ) {
      if ( exists $error_for{order_date} ) {
          $error_for{order_date} = "You must enter a valid order date";
      }
  }

If a date is required, it's easy to handle this:

  use Class::CGI
    handlers => {
        date       => 'Class::CGI::DateTime',
        order_date => 'Class::CGI::DateTime',
    };
  my $cgi        = Class::CGI->new;
  $cgi->required( qw/date order_date/ );
  my $date       = $cgi->param('date');
  my $order_date = $cgi->param('order_date');

C<Class::CGI::DateTime> will not create a date object if any of the required
components (day, month, year and so on) are missing.  Further, a descriptive
error message will be set.

Also note that at the present time, C<Class::CGI::DateTime> only ensures that
we can create a valid C<DateTime> object.  Application-specific validation
(such as ensuring the date is in the future) belongs in your application and
should be handled there.

=cut

sub handle {
    my $self  = shift;
    my $cgi   = $self->cgi;
    my $param = $self->param;

    my @params = $self->components;

    # original param name and param value
    my %args = map { /([[:word:]]+)$/; $1, $cgi->raw_param($_) } @params;

    # untaint them puppies
    while ( my ( $arg, $value ) = each %args ) {
        if ( 'time_zone' eq $arg ) {
            $value =~ /^(floating|local|\+[[:digit:]]+|[[:word:]]+\/[[:word:]]+)$/;
            $args{$arg} = $1;
        }
        else {
            $value =~ /^(\d+)$/;
            $args{$arg} = $1;
        }
    }
    my $datetime;
 
    eval { $datetime = DateTime->new(%args) };

    if (my $error = $@) {
        $cgi->add_error( $param, 'You must supply a valid date' );
    }
    return $datetime;
}

sub components {
    my $self  = shift;
    my $cgi   = $self->cgi;
    my $param = $self->param;

    my $requested_params = $cgi->args($param);
    my @params = $requested_params 
      ? @{ $requested_params->{params} }
      : qw(day month year);

    if ( 'date' ne $param ) {
        @params = map {"$param.$_"} @params;
    }
    return @params;
}

sub has_param {
    my $self = shift;
    return $self->has_virtual_param( $self->param, $self->components );
}

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-cgi-datetime@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-CGI-DateTime>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

=over 4

=item * 
DateTime - A date and time object 

=back

=head1 ACKNOWLEDGEMENTS

Adam Kennedy (Alias):  for suggesting a better interface.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
