package Rose::Object::MakeMethods::DateTime;

use strict;

use Carp();

our $VERSION = '0.81';

use Rose::Object::MakeMethods;
our @ISA = qw(Rose::Object::MakeMethods);

use Rose::DateTime::Util();

sub datetime
{
  my($class, $name, $args) = @_;

  my %methods;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';
  my $tz = $args->{'tz'};

  if($interface eq 'get_set')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      if(@_)
      {
        if(@_ == 2)
        {
          if($_[0] eq 'format')
          {
            return Rose::DateTime::Util::format_date($self->{$key}, ((ref $_[1]) ? @{$_[1]} : $_[1]));
          }
          elsif($_[0] eq 'truncate')
          {
            return undef  unless($self->{$key});
            return $self->{$key}  unless(ref $self->{$key});
            return $self->{$key}->clone->truncate(to => $_[1]);
          }
          else { Carp::croak "Invalid arguments for $name attribute: @_" }
        }
        elsif(@_ > 1)
        {
          Carp::croak "Too many arguments for $name attribute: @_";
        }

        $self->{$key} = Rose::DateTime::Util::parse_date($_[0], $tz || ()) 
          or Carp::croak("Invalid date: '$_[0]'");
      }

      return $self->{$key};
    }
  }
  elsif($interface eq 'get_set_init')
  {
    my $init_method = $args->{'init_method'} || "init_$name";

    $methods{$name} = sub
    {
      my($self) = shift;

      if(@_)
      {
        if(@_ == 2)
        {
          my $arg = $self->$init_method();

          $self->{$key} = Rose::DateTime::Util::parse_date($arg, $tz || ()) 
            or Carp::croak("Invalid date: '$arg'");

          if($_[0] eq 'format')
          {
            return Rose::DateTime::Util::format_date($self->{$key}, ((ref $_[1]) ? @{$_[1]} : $_[1]));
          }
          elsif($_[0] eq 'truncate')
          {
            return undef  unless($self->{$key});
            return $self->{$key}  unless(ref $self->{$key});
            return $self->{$key}->clone->truncate(to => $_[1]);
          }
          else { Carp::croak "Invalid arguments for $name attribute: @_" }
        }
        elsif(@_ > 1)
        {
          Carp::croak "Too many arguments for $name attribute: @_";
        }

        $self->{$key} = Rose::DateTime::Util::parse_date($_[0], $tz || ()) 
          or Carp::croak("Invalid date: '$_[0]'");
      }

      return $self->{$key}   if(defined $self->{$key});

      my $arg = $self->$init_method();

      $self->{$key} = Rose::DateTime::Util::parse_date($arg, $tz || ()) 
        or Carp::croak("Invalid date: '$arg'");

      return $self->{$key};
    }
  }  
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

1;

__END__

=head1 NAME

Rose::Object::MakeMethods::DateTime - Create methods that store DateTime objects.

=head1 SYNOPSIS

  package MyObject;

  use Rose::Object::MakeMethods::DateTime
  (
    datetime => 
    [
      'birthday',
      'arrival' => { tz => 'UTC' }
    ],
  );

  ...

  $obj = MyObject->new(birthday => '1/24/1984 1am');

  $dt = $obj->birthday; # DateTime object

  $bday = $obj->birthday(format => '%B %E'); # 'January 24th'

  # Shortcut for $obj->birthday->clone->truncate(to => 'month');
  $month = $obj->birthday(truncate => 'month');

  $obj->birthday('blah');       # croaks - invalid date!
  $obj->birthday('1999-04-31'); # croaks - invalid date!

=head1 DESCRIPTION

L<Rose::Object::MakeMethods::DateTime> is a method maker that inherits
from L<Rose::Object::MakeMethods>.  See the L<Rose::Object::MakeMethods>
documentation to learn about the interface.  The method types provided
by this module are described below.  All methods work only with
hash-based objects.

=head1 METHODS TYPES

=over 4

=item B<datetime>

Create get/set methods for scalar attributes that store L<DateTime>
objects.

=over 4

=item Options

=over 4

=item C<hash_key>

The key inside the hash-based object to use for the storage of this
attribute. Defaults to the name of the method.

=item C<init_method>

The name of the method to call when initializing the value of an
undefined attribute.  This option is only applicable when using the
C<get_set_init> interface. Defaults to the method name with the prefix
C<init_> added.

This method should return a value that can be parsed by
L<Rose::DateTime::Util>'s the L<parse_date()|Rose::DateTime::Util/parse_date>
function. If the return value is a L<DateTime> object, it will have its time
zone set (see the C<tz> option below) using L<DateTime>'s
L<set_time_zone()|DateTime/set_time_zone> method.

=item C<interface>

Chooses one of the two possible interfaces.  Defaults to C<get_set>.

=item C<tz>

The time zone of the L<DateTime> object to be stored.  If present, this value
will be passed as the second argument to L<Rose::DateTime::Util>'s the
L<parse_date()|Rose::DateTime::Util/parse_date> function when creating
L<DateTime> objects for storage. If absent, L<DateTime> objects will use the
default time zone of the L<Rose::DateTime::Util> class, which is set by
L<Rose::DateTime::Util>'s L<time_zone()|Rose::DateTime::Util/time_zone> class
method.  See the L<Rose::DateTime::Util> documentation for more information.

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a get/set accessor method for an object attribute that stores a
L<DateTime> object.

When called with a single argument, the argument is passed through
L<Rose::DateTime::Util>'s L<parse_date()|Rose::DateTime::Util/parse_date>
function in order to create the L<DateTime> object that is stored.  The
current value of the attribute is returned.  Passing a value that is not
understood by L<Rose::DateTime::Util>'s
L<parse_date()|Rose::DateTime::Util/parse_date> function causes a fatal error.

When called with two arguments and the first argument is the string 'format',
then the second argument is taken as a format specifier which is passed to
L<Rose::DateTime::Util>'s L<format_date()|Rose::DateTime::Util/format_date>
function.  The formatted string is returned.  In other words, this:

    $obj->birthday(format => '%m/%d/%Y');

Is just a shortcut for this:

    Rose::DateTime::Util::format_date($obj->birthday, 
                                      '%m/%d/%Y');

When called with two arguments and the first argument is the string
'truncate', then the second argument is taken as a truncation specifier which
is passed to L<DateTime>'s L<truncate()|DateTime/truncate> method called on a
clone of the existing L<DateTime> object.  The cloned, truncated L<DateTime>
object is returned.  In other words, this:

    $obj->birthday(truncate => 'month');

Is just a shortcut for this:

    $obj->birthday->clone->truncate(to => 'month');

Passing more than two arguments or passing two arguments where the
first argument is not 'format' or 'truncate' will cause a fatal error.

=item C<get_set_init> 

Behaves like the C<get_set> interface unless the value of the attribute is
undefined.  In that case, the method specified by the C<init_method> option is
called, the return value is passed through L<Rose::DateTime::Util>'s
L<parse_date()|Rose::DateTime::Util/parse_date> function, and the attribute is
set to the return value.  An init method that returns a value that is not
understood by L<Rose::DateTime::Util>'s
L<parse_date()|Rose::DateTime::Util/parse_date> function will cause a fatal
error.

=back

=back

Example:

    package MyObject;

    use Rose::Object::MakeMethods::DateTime
    (
      datetime => 
      [
        'birthday',
        'arrival' => { tz => 'UTC' }
      ],

      'datetime --get_set_init' =>
      [
        'departure' => { tz => 'UTC' }
      ],
    );

    sub init_departure 
    {
      DateTime->new(month => 1, 
                    day   => 10,
                    year  => 2000,
                    time_zone => 'America/Chicago');
    }

    ...

    $obj = MyObject->new(birthday => '1/24/1984 1am');

    $dt = $obj->birthday; # DateTime object

    $bday = $obj->birthday(format => '%B %E'); # 'January 24th'

    # Shortcut for $obj->birthday->clone->truncate(to => 'month');
    $month = $obj->birthday(truncate => 'month');

    $obj->birthday('blah');       # croaks - invalid date!
    $obj->birthday('1999-04-31'); # croaks - invalid date!

    # DateTime object with time zone set to UTC
    $dt = $obj->arrival('2005-21-01 4pm');

    # DateTime object with time zone set to UTC, not America/Chicago!
    #   Start with 2000-01-10T00:00:00 America/Chicago,
    #   then set_time_zone('UTC'), 
    #   which results in: 2000-01-10T06:00:00 UTC
    $dt = $obj->departure;

    print $dt; # "2000-01-10T06:00:00"

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

