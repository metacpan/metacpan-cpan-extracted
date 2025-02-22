package Rose::DateTime::Parser;

use strict;

use Rose::DateTime::Util();

use Rose::Object;
our @ISA = qw(Rose::Object);

use Rose::Object::MakeMethods::Generic
(
  scalar  => 'error',
  'scalar --get_set_init' => 'time_zone',
);

our $VERSION = '0.50';

sub init_time_zone { Rose::DateTime::Util->time_zone }
sub init_european  { Rose::DateTime::Util->european_dates }

sub european
{
  my($self) = shift;

  if(@_)
  {
    if(defined $_[0])
    {
      return $self->{'european'} = $_[0] ? 1 : 0;
    }
    else { $self->{'european'} = undef }
  }

  return $self->{'european'}  if(defined $self->{'european'});
  $self->{'european'} = $self->init_european;
}

sub parse_date
{
  my($self) = shift;

  my $date;

  if($self->european)
  {
    $date = Rose::DateTime::Util::parse_european_date(shift, $self->time_zone);
  }
  else
  {
    local $Rose::DateTime::Util::European_Dates = 0;
    $date = Rose::DateTime::Util::parse_date(shift, $self->time_zone);
  }

  return $date  if($date);
  $self->error(Rose::DateTime::Util->error);
  return $date;
}

*parse_datetime = \&parse_date;

sub parse_european_date
{
  my($self) = shift;
  my $date = Rose::DateTime::Util::parse_european_date(shift, $self->time_zone);
  return $date  if($date);
  $self->error(Rose::DateTime::Util->error);
  return $date;
}

1;

__END__

=head1 NAME

Rose::DateTime::Parser - DateTime parser object.

=head1 SYNOPSIS

  use Rose::DateTime::Parser;

  $parser = Rose::DateTime::Parser->new(time_zone => 'UTC');

  $dt = $parser->parse_date('4/30/2001 8am')
    or warn $parser->error;


=head1 DESCRIPTION

L<Rose::DateTime::Parser> encapsulates a particular kind of call to L<Rose::DateTime::Util>'s L<parse_date|Rose::DateTime::Util/parse_date> and L<parse_european_date|Rose::DateTime::Util/parse_european_date> functions.  The object maintains the desired time zone, which is then passed to each call.

This class inherits from, and follows the conventions of, L<Rose::Object>. See the L<Rose::Object> documentation for more information.

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::DateTime::Parser> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<error [ERROR]>

Get or set the error message string.

=item B<european [BOOL]>

Get or set a boolean value that controls how the L<parse_date|/parse_date> method will interpret "xx/xx/xxxx" dates: either month/day/year or year/month/day.

If true, then the L<parse_date|/parse_date> method will pass its arguments to L<Rose::DateTime::Util>'s L<parse_european_date|Rose::DateTime::Util/parse_european_date> function, which interprets such dates as "dd/mm/yyyy". 

If false, then the L<parse_date|/parse_date> method will temporarily B<force> non-European date parsing and then call L<Rose::DateTime::Util>'s L<parse_date|Rose::DateTime::Util/parse_date> function, which will interpret the date as "mm/dd/yyyy".

This attribute defaults to the value returned by the L<Rose::DateTime::Util-E<gt>european_dates|Rose::DateTime::Util/european_dates> class method called I<at the time the L<Rose::DateTime::Parser> object is constructed>.

If the BOOL argument is undefined (instead of "false, but defined") then the attribute will return to its default value by calling the L<Rose::DateTime::Util-E<gt>european_dates|Rose::DateTime::Util/european_dates> class method again.  To unambiguously set the attribute to true or false, pass a defined value like 1 or 0.

=item B<parse_date STRING>

Attempt to parse STRING by passing it to L<Rose::DateTime::Util>'s L<parse_date|Rose::DateTime::Util/parse_date> or L<parse_european_date|Rose::DateTime::Util/parse_european_date> function.  The choice is controlled by the L<european|/european> attribute.

If parsing is successful, the resulting L<DateTime> object is returned.  Otherwise, L<error|/error> is set and false is returned.

=item B<parse_datetime STRING>

This method is an alias for L<parse_date()|/parse_date>

=item B<parse_european_date STRING>

Attempt to parse STRING by passing it to L<Rose::DateTime::Util>'s L<parse_european_date|Rose::DateTime::Util/parse_european_date> function (regardless of the value of the  L<european|/european> attribute). If parsing is successful, the resulting L<DateTime> object is returned.  Otherwise, L<error|/error> is set and false is returned.

=item B<time_zone [STRING]>

Get or set the time zone string passed to L<Rose::DateTime::Util>'s L<parse_date|Rose::DateTime::Util/parse_date> function.  Defaults to the value returned by the L<Rose::DateTime::Util-E<gt>time_zone|Rose::DateTime::Util/time_zone> class method.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
