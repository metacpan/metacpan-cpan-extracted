package Rose::DB::Object::MakeMethods::Time;

use strict;

use Carp();

use Rose::Object::MakeMethods;
our @ISA = qw(Rose::Object::MakeMethods);

use Rose::DB::Object::Constants
  qw(PRIVATE_PREFIX FLAG_DB_IS_PRIVATE STATE_IN_DB STATE_LOADING
     STATE_SAVING MODIFIED_COLUMNS MODIFIED_NP_COLUMNS SET_COLUMNS);

use Rose::DB::Object::Util qw(column_value_formatted_key);

our $VERSION = '0.771';

sub interval
{
  my($class, $name, $args) = @_;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  my $column_name = $args->{'column'} ? $args->{'column'}->name : $name;

  my $undef_overrides_default = $args->{'undef_overrides_default'} || 0;

  my $formatted_key = column_value_formatted_key($key);
  my $default = $args->{'default'};

  my $eomm = $args->{'end_of_month_mode'};

  my $mod_columns_key = ($args->{'column'} ? $args->{'column'}->nonpersistent : 0) ? 
    MODIFIED_NP_COLUMNS : MODIFIED_COLUMNS;

  my %methods;

  if($interface eq 'get_set')
  {
    $methods{$name} = sub
    {
      my $self = shift;

      my $db = $self->db or die "Missing Rose::DB object attribute";
      my $driver = $db->driver || 'unknown';

      if(@_)
      {
        if(defined $_[0])
        {
          if($self->{STATE_LOADING()})
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $_[0];
          }
          else
          {
            my $dt_duration = $db->parse_interval($_[0], $eomm);
            Carp::croak $db->error  unless(defined $dt_duration);

            if(ref $dt_duration)
            {
              $self->{$key} = $dt_duration;
              $self->{$formatted_key,$driver} = undef;
            }
            else
            {
              $self->{$key} = undef;
              $self->{$formatted_key,$driver} = $dt_duration;
            }

            $self->{$mod_columns_key}{$column_name} = 1;
          }
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = undef;
          $self->{$mod_columns_key}{$column_name} = 1
            unless($self->{STATE_LOADING()});
        }
      }

      return  unless(defined wantarray);

      unless(!defined $default || defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
             ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
              ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
      {
        my $dt_duration = $db->parse_interval($default, $eomm);
        Carp::croak $db->error  unless(defined $dt_duration);

        if(ref $dt_duration)
        {
          $self->{$key} = $dt_duration;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $dt_duration;
        }

        $self->{$mod_columns_key}{$column_name} = 1
          unless($self->{STATE_IN_DB()});
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || $self->{$formatted_key,$driver}) ? 
          ($self->{$formatted_key,$driver} ||= $db->format_interval($self->{$key})) : undef;
      }

      return $self->{$key} ? $self->{$key} : 
             $self->{$formatted_key,$driver} ? 
             ($self->{$key} = $db->parse_interval($self->{$formatted_key,$driver}, $eomm)) : undef;
    };
  }
  elsif($interface eq 'get')
  {
    $methods{$name} = sub
    {
      my $self = shift;

      my $db = $self->db or die "Missing Rose::DB object attribute";
      my $driver = $db->driver || 'unknown';

      unless(!defined $default || defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
             ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
              ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
      {
        my $dt_duration = $db->parse_interval($default, $eomm);
        Carp::croak $db->error  unless(defined $dt_duration);

        if(ref $dt_duration)
        {
          $self->{$key} = $dt_duration;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $dt_duration;
        }

        $self->{$mod_columns_key}{$column_name} = 1;
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || $self->{$formatted_key,$driver}) ? 
          ($self->{$formatted_key,$driver} ||= $db->format_interval($self->{$key})) : undef;
      }

      return $self->{$key} ? $self->{$key} : 
             $self->{$formatted_key,$driver} ? 
             ($self->{$key} = $db->parse_interval($self->{$formatted_key,$driver}, $eomm)) : undef;
    };
  }
  elsif($interface eq 'set')
  {
    $methods{$name} = sub
    {
      my $self = shift;

      my $db = $self->db or die "Missing Rose::DB object attribute";
      my $driver = $db->driver || 'unknown';

      Carp::croak "Missing argument in call to $name"  unless(@_);

      if(defined $_[0])
      {
        if($self->{STATE_LOADING()})
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $_[0];
        }
        else
        {
          my $dt_duration = $db->parse_interval($_[0], $eomm);
          Carp::croak $db->error  unless(defined $dt_duration);

          if(ref $dt_duration)
          {
            $self->{$key} = $dt_duration;
            $self->{$formatted_key,$driver} = undef;
          }
          else
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $dt_duration;
          }
        }
      }
      else
      {
        $self->{$key} = undef;
        $self->{$formatted_key,$driver} = undef;
      }

      $self->{$mod_columns_key}{$column_name} = 1;

      return  unless(defined wantarray);

      unless(!defined $default || defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
             ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
              ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
      {
        my $dt_duration = $db->parse_interval($default, $eomm);
        Carp::croak $db->error  unless(defined $dt_duration);

        if(ref $dt_duration)
        {
          $self->{$key} = $dt_duration;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $dt_duration;
        }
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || $self->{$formatted_key,$driver}) ? 
          ($self->{$formatted_key,$driver} ||= $db->format_interval($self->{$key})) : undef;
      }

      return $self->{$key} ? $self->{$key} : 
             $self->{$formatted_key,$driver} ? 
             ($self->{$key} = $db->parse_interval($self->{$formatted_key,$driver}, $eomm)) : undef;
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub time
{
  my($class, $name, $args) = @_;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  my $column_name = $args->{'column'} ? $args->{'column'}->name : $name;

  my $undef_overrides_default = $args->{'undef_overrides_default'} || 0;

  my $formatted_key = column_value_formatted_key($key);
  my $default = $args->{'default'};
  my $precision = $args->{'precision'};

  my $mod_columns_key = ($args->{'column'} ? $args->{'column'}->nonpersistent : 0) ? 
    MODIFIED_NP_COLUMNS : MODIFIED_COLUMNS;

  my %methods;

  if($interface eq 'get_set')
  {
    $methods{$name} = sub
    {
      my $self = shift;

      my $db = $self->db or die "Missing Rose::DB object attribute";
      my $driver = $db->driver || 'unknown';

      if(@_)
      {
        if(defined $_[0])
        {
          if($self->{STATE_LOADING()})
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $_[0];
          }
          else
          {
            my $time = $db->parse_time($_[0]);
            Carp::croak $db->error  unless(defined $time);

            if(ref $time)
            {
              $self->{$key} = $time;
              $self->{$formatted_key,$driver} = undef;
            }
            else
            {
              $self->{$key} = undef;
              $self->{$formatted_key,$driver} = $time;
            }

            $self->{$mod_columns_key}{$column_name} = 1;
          }
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = undef;
          $self->{$mod_columns_key}{$column_name} = 1
            unless($self->{STATE_LOADING()});
        }
      }

      return  unless(defined wantarray);

      unless(!defined $default || defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
             ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
              ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
      {
        my $time = $db->parse_time($default);
        Carp::croak $db->error  unless(defined $time);

        if(ref $time)
        {
          $self->{$key} = $time;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $time;
        }

        $self->{$mod_columns_key}{$column_name} = 1
          unless($self->{STATE_IN_DB()});
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || $self->{$formatted_key,$driver}) ? 
          ($self->{$formatted_key,$driver} ||= $db->format_time($self->{$key}, $precision)) : undef;
      }

      return $self->{$key} ? $self->{$key} : 
             $self->{$formatted_key,$driver} ? 
             ($self->{$key} = $db->parse_time($self->{$formatted_key,$driver})) : undef;
    };
  }
  elsif($interface eq 'get')
  {
    $methods{$name} = sub
    {
      my $self = shift;

      my $db = $self->db or die "Missing Rose::DB object attribute";
      my $driver = $db->driver || 'unknown';

      unless(!defined $default || defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
             ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
              ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
      {
        my $time = $db->parse_time($default);
        Carp::croak $db->error  unless(defined $time);

        if(ref $time)
        {
          $self->{$key} = $time;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $time;
        }

        $self->{$mod_columns_key}{$column_name} = 1;
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || $self->{$formatted_key,$driver}) ? 
          ($self->{$formatted_key,$driver} ||= $db->format_time($self->{$key}, $precision)) : undef;
      }

      return $self->{$key} ? $self->{$key} : 
             $self->{$formatted_key,$driver} ? 
             ($self->{$key} = $db->parse_time($self->{$formatted_key,$driver})) : undef;
    };
  }
  elsif($interface eq 'set')
  {
    $methods{$name} = sub
    {
      my $self = shift;

      my $db = $self->db or die "Missing Rose::DB object attribute";
      my $driver = $db->driver || 'unknown';

      Carp::croak "Missing argument in call to $name"  unless(@_);

      if(defined $_[0])
      {
        if($self->{STATE_LOADING()})
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $_[0];
        }
        else
        {
          my $time = $db->parse_time($_[0]);
          Carp::croak $db->error  unless(defined $time);

          if(ref $time)
          {
            $self->{$key} = $time;
            $self->{$formatted_key,$driver} = undef;
          }
          else
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $time;
          }
        }
      }
      else
      {
        $self->{$key} = undef;
        $self->{$formatted_key,$driver} = undef;
      }

      $self->{$mod_columns_key}{$column_name} = 1;

      return  unless(defined wantarray);

      unless(!defined $default || defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
             ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
              ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
      {
        my $time = $db->parse_time($default);
        Carp::croak $db->error  unless(defined $time);

        if(ref $time)
        {
          $self->{$key} = $time;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $time;
        }
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || $self->{$formatted_key,$driver}) ? 
          ($self->{$formatted_key,$driver} ||= $db->format_time($self->{$key}, $precision)) : undef;
      }

      return $self->{$key} ? $self->{$key} : 
             $self->{$formatted_key,$driver} ? 
             ($self->{$key} = $db->parse_time($self->{$formatted_key,$driver})) : undef;
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

1;

__END__

=head1 NAME

Rose::DB::Object::MakeMethods::Time - Create time-related methods for Rose::DB::Object-derived objects.

=head1 SYNOPSIS

    package MyDBObject;

    use base 'Rose::DB::Object';

    use Rose::DB::Object::MakeMethods::Time
    (
      interval => 
      [
        t1 => { scale => 6 },
        t2 => { default => '3 days 6 minutes 5 seconds' },
      ],

      time =>
      [
        start => { scale => 5 },
        end   => { default => '12:34:56' },
      ],
    );

    ...

    $o->t1('5 minutes 0.003 seconds');

    $dt_dur = $o->t1; # DateTime::Duration object

    print $o->t1->minutes;    # 5
    print $o->t1->nanosecond; # 3000000

    $o->start('12:34:56.12345');

    print $o->start->nanosecond; # 123450000
    print $o->start->as_string;  # 12:34:56.12345

    $o->end('6pm');

    $tc = $o->end; # Time::Clock object

    print $o->end->hour; # 18
    print $o->end->ampm; # PM

    print $o->end->format('%I:%M %p'); # 6:00 PM
    $o->end->add(hours => 1);
    print $o->end->format('%I:%M %p'); # 7:00 PM

=head1 DESCRIPTION

C<Rose::DB::Object::MakeMethods::Time> creates methods that deal with times, and inherits from L<Rose::Object::MakeMethods>.  See the L<Rose::Object::MakeMethods> documentation to learn about the interface.  The method types provided by this module are described below.

All method types defined by this module are designed to work with objects that are subclasses of (or otherwise conform to the interface of) L<Rose::DB::Object>.  In particular, the object is expected to have a L<db|Rose::DB::Object/db> method that returns a L<Rose::DB>-derived object.  See the L<Rose::DB::Object> documentation for more details.

=head1 METHODS TYPES

=over 4

=item B<interval>

Create get/set methods for interval (years, months, days, hours, minutes, seconds) attributes.

=over 4

=item Options

=over 4

=item C<default>

Determines the default value of the attribute.

=item C<end_of_month_mode>

This mode determines how math is done on duration objects.  If defined, the C<end_of_month> setting for each L<DateTime::Duration> object created by this method will be set to the specified mode.  Otherwise, the C<end_of_month> parameter will not be passed to the L<DateTime::Duration> constructor.

Valid modes are C<wrap>, C<limit>, and C<preserve>.  See the documentation for L<DateTime::Duration> for a full explanation.

=item C<hash_key>

The key inside the hash-based object to use for the storage of this
attribute.  Defaults to the name of the method.

=item C<interface>

Choose the interface.  The default is C<get_set>.

=item C<scale>

An integer number of places past the decimal point preserved for fractional seconds.  Defaults to 0.

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a get/set method for a interval (years, months, days, hours, minutes, seconds) attribute.  When setting the attribute, the value is passed through the L<parse_interval|Rose::DB/parse_interval> method of the object's L<db|Rose::DB::Object/db> attribute.  If that fails, a fatal error will occur.

When saving to the database, the method will pass the attribute value through the L<format_interval|Rose::DB/format_interval> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.

This method is designed to allow interval values to make a round trip from and back into the database without ever being "inflated" into L<DateTime::Duration> objects.  Any use of the attribute (get or set) outside the context of loading from or saving to the database will cause the value to be "inflated" using the  L<parse_interval|Rose::DB/parse_interval> method of the object's L<db|Rose::DB::Object/db> attribute.

=item C<get>

Creates an accessor method for a interval (years, months, days, hours, minutes, seconds) attribute.  This method behaves like the C<get_set> method, except that the value cannot be set. 

=item C<set>

Creates a mutator method for a interval (years, months, days, hours, minutes, seconds) attribute.  This method behaves like the C<get_set> method, except that a fatal error will occur if no arguments are passed.

=back

=back

Example:


    package MyDBObject;

    use base 'Rose::DB::Object';

    use Rose::DB::Object::MakeMethods::Time
    (
      time => 
      [
        't1' => { scale => 6 },
        't2' => { default => '3 days 6 minutes 5 seconds' },
      ],
    );

    ...

    $o->t1('5 minutes 0.003 seconds');

    $dt_dur = $o->t1; # DateTime::Duration object

    print $o->t1->minutes;    # 5
    print $o->t1->nanosecond; # 3000000

=item B<time>

Create get/set methods for time (hours, minutes, seconds) attributes.  Fractional seconds up to nanosecond precision are supported.

=over 4

=item Options

=over 4

=item C<default>

Determines the default value of the attribute.

=item C<hash_key>

The key inside the hash-based object to use for the storage of this
attribute.  Defaults to the name of the method.

=item C<interface>

Choose the interface.  The default is C<get_set>.

=item C<scale>

An integer number of places past the decimal point preserved for fractional seconds.  Defaults to 0.  The maximum value is 9.

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a get/set method for a time attribute.  When setting the attribute, the value is passed through the L<parse_time|Rose::DB/parse_time> method of the object's L<db|Rose::DB::Object/db> attribute.  If that fails, a fatal error will occur.

When saving to the database, the method will pass the attribute value through the L<format_time|Rose::DB/format_time> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.

This method is designed to allow time values to make a round trip from and back into the database without ever being "inflated" into L<Time::Clock> objects.  Any use of the attribute (get or set) outside the context of loading from or saving to the database will cause the value to be "inflated" using the  L<parse_time|Rose::DB/parse_time> method of the object's L<db|Rose::DB::Object/db> attribute.

=item C<get>

Creates an accessor method for a time attribute.  This method behaves like the C<get_set> method, except that the value cannot be set. 

=item C<set>

Creates a mutator method for a time attribute.  This method behaves like the C<get_set> method, except that a fatal error will occur if no arguments are passed.

=back

=back

Example:

    package MyDBObject;

    use base 'Rose::DB::Object';

    use Rose::DB::Object::MakeMethods::Time
    (
      time =>
      [
        start => { scale => 5 },
        end   => { default => '12:34:56' },
      ],
    );

    ...

    $o->start('12:34:56.12345');

    print $o->start->nanosecond; # 123450000
    print $o->start->as_string;  # 12:34:56.12345

    $o->end('6pm');

    $tc = $o->end; # Time::Clock object

    print $o->end->hour; # 18
    print $o->end->ampm; # PM

    print $o->end->format('%I:%M %p'); # 6:00 PM
    $o->end->add(hours => 1);
    print $o->end->format('%I:%M %p'); # 7:00 PM

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
