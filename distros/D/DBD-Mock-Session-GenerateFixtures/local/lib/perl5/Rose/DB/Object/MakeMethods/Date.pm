package Rose::DB::Object::MakeMethods::Date;

use strict;

use Carp();

use Rose::Object::MakeMethods;
our @ISA = qw(Rose::Object::MakeMethods);

use Rose::DB::Object::Constants
  qw(PRIVATE_PREFIX FLAG_DB_IS_PRIVATE STATE_IN_DB STATE_LOADING
     STATE_SAVING MODIFIED_COLUMNS MODIFIED_NP_COLUMNS SET_COLUMNS);

use Rose::DB::Object::Util qw(column_value_formatted_key);

our $VERSION = '0.787';

sub date
{
  my($class, $name, $args) = @_;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';
  my $tz = $args->{'time_zone'} || 0;

  my $column_name = $args->{'column'} ? $args->{'column'}->name : $name;

  my $undef_overrides_default = $args->{'undef_overrides_default'} || 0;

  my $formatted_key = column_value_formatted_key($key);
  my $default = $args->{'default'};

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
        if(@_ == 2)
        {
          my $dt = $self->{$key} || $self->{$formatted_key,$driver};

          if(defined $dt && !ref $dt)
          {
            my $dt2 = $db->parse_date($dt);

            unless($dt2)
            {
              $dt2 = Rose::DateTime::Util::parse_date($dt, $tz || $db->server_time_zone) or
                Carp::croak "Could not parse date '$dt'";
            }

            $dt = $dt2;
          }

          if($_[0] eq 'format')
          {
            return $dt  unless(ref $dt);
            return Rose::DateTime::Util::format_date($dt, (ref $_[1] ? @{$_[1]} : $_[1]));
          }
          elsif($_[0] eq 'truncate')
          {
            return undef  unless($self->{$key});
            return $dt  unless(ref $dt);
            return $dt->clone->truncate(to => $_[1]);
          }
          else
          {
            Carp::croak "Invalid argument(s) to $name: @_";
          }
        }

        if(defined $_[0])
        {
          if($self->{STATE_LOADING()})
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $_[0];
          }
          else
          {
            my $dt = $db->parse_date($_[0]);

            unless($dt)
            {
              $dt = Rose::DateTime::Util::parse_date($_[0], $tz || $db->server_time_zone) or
                Carp::croak "Invalid date: '$_[0]'";
            }

            if(ref $dt)
            {
              $dt->set_time_zone($tz || $db->server_time_zone);
              $self->{$key} = $dt;
              $self->{$formatted_key,$driver} = undef;
            }
            else
            {
              $self->{$key} = undef;
              $self->{$formatted_key,$driver} = $dt;
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
        my $dt = $db->parse_date($default);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($default, $tz || $db->server_time_zone) or
            Carp::croak "Invalid default date: '$default'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
          $self->{$key} = $dt;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $dt;
        }

        $self->{$mod_columns_key}{$column_name} = 1
          unless($self->{STATE_IN_DB()});
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || $self->{$formatted_key,$driver}) ? 
          ($self->{$formatted_key,$driver} ||= $db->format_date($self->{$key})) : undef;
      }

      return $self->{$key}   if($self->{$key});

      if(my $value = $self->{$formatted_key,$driver})
      {
        my $dt = $db->parse_date($value);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($value, $tz || $db->server_time_zone) or
            Carp::croak "Invalid date: '$value'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
        }

        return $self->{$key} = $dt;
      }

      return undef;
    };
  }
  elsif($interface eq 'get')
  {
    $methods{$name} = sub
    {
      my $self = shift;

      my $db = $self->db or die "Missing Rose::DB object attribute";
      my $driver = $db->driver || 'unknown';

      if(@_ == 2)
      {
        my $dt = $self->{$key} || $self->{$formatted_key,$driver};

        if(defined $dt && !ref $dt)
        {
          my $dt2 = $db->parse_date($dt);

          unless($dt2)
          {
            $dt2 = Rose::DateTime::Util::parse_date($dt, $tz || $db->server_time_zone) or
              Carp::croak "Could not parse date '$dt'";
          }

          $dt = $dt2;
        }

        if($_[0] eq 'format')
        {
          return $dt  unless(ref $dt);
          return Rose::DateTime::Util::format_date($dt, (ref $_[1] ? @{$_[1]} : $_[1]));
        }
        elsif($_[0] eq 'truncate')
        {
          return undef  unless($self->{$key});
          return $dt  unless(ref $dt);
          return $dt->clone->truncate(to => $_[1]);
        }
        else
        {
          Carp::croak "Invalid argument(s) to $name: @_";
        }
      }

      unless(!defined $default || defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
             ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
              ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
      {
        my $dt = $db->parse_date($default);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($default, $tz || $db->server_time_zone) or
            Carp::croak "Invalid default date: '$default'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
          $self->{$key} = $dt;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $dt;
        }

        $self->{$mod_columns_key}{$column_name} = 1
          unless($self->{STATE_IN_DB()});
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || $self->{$formatted_key,$driver}) ? 
          ($self->{$formatted_key,$driver} ||= $db->format_date($self->{$key})) : undef;
      }

      return $self->{$key}   if($self->{$key});

      if(my $value = $self->{$formatted_key,$driver})
      {
        my $dt = $db->parse_date($value);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($value, $tz || $db->server_time_zone) or
            Carp::croak "Invalid date: '$value'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
        }

        return $self->{$key} = $dt;
      }

      return undef;
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
          my $dt = $db->parse_date($_[0]);

          unless($dt)
          {
            $dt = Rose::DateTime::Util::parse_date($_[0], $tz || $db->server_time_zone) or
              Carp::croak "Invalid date: '$_[0]'";
          }

          if(ref $dt)
          {
            $dt->set_time_zone($tz || $db->server_time_zone);
            $self->{$key} = $dt;
            $self->{$formatted_key,$driver} = undef;
          }
          else
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $dt;
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

      return  unless(defined wantarray);

      unless(!defined $default || defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
             ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
              ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
      {
        my $dt = $db->parse_date($default);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($default, $tz || $db->server_time_zone) or
            Carp::croak "Invalid default date: '$default'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
          $self->{$key} = $dt;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $dt;
        }

        $self->{$mod_columns_key}{$column_name} = 1
          unless($self->{STATE_IN_DB()});
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || $self->{$formatted_key,$driver}) ? 
          ($self->{$formatted_key,$driver} ||= $db->format_date($self->{$key})) : undef;
      }

      return $self->{$key}   if($self->{$key});

      if(my $value = $self->{$formatted_key,$driver})
      {
        my $dt = $db->parse_date($value);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($value, $tz || $db->server_time_zone) or
            Carp::croak "Invalid date: '$value'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
        }

        return $self->{$key} = $dt;
      }

      return undef;
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub datetime
{
  my($class, $name, $args) = @_;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';
  my $type = $args->{'type'} || 'datetime';
  my $tz = $args->{'time_zone'} || 0;

  my $column_name = $args->{'column'} ? $args->{'column'}->name : $name;

  my $undef_overrides_default = $args->{'undef_overrides_default'} || 0;

  for($type)
  {
    # "datetime year to fraction(5)" -> datetime_year_to_fraction_5
    tr/ /_/;
    s/\(([1-5])\)$/_$1/; 
  }

  my $format_method = "format_$type";
  my $parse_method  = "parse_$type";

  my $formatted_key = column_value_formatted_key($key);
  my $default = $args->{'default'};

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
        if(@_ == 2)
        {
          my $dt = $self->{$key} || $self->{$formatted_key,$driver};

          if(defined $dt && !ref $dt)
          {
            my $dt2 = $db->$parse_method($dt);

            unless($dt2)
            {
              $dt2 = Rose::DateTime::Util::parse_date($dt, $tz || $db->server_time_zone);
                Carp::croak "Could not parse datetime '$dt'";
            }

            $dt = $dt2;
          }

          if($_[0] eq 'format')
          {
            return $dt  unless(ref $dt);
            return Rose::DateTime::Util::format_date($dt, (ref $_[1] ? @{$_[1]} : $_[1]));
          }
          elsif($_[0] eq 'truncate')
          {
            return undef  unless($self->{$key});
            return $db->$format_method($dt)  unless(ref $dt);
            return $dt->clone->truncate(to => $_[1]);
          }
          else
          {
            Carp::croak "Invalid argument(s) to $name: @_";
          }
        }

        if(defined $_[0])
        {
          if($self->{STATE_LOADING()})
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $_[0];
          }
          else
          {
            my $dt = $db->$parse_method($_[0]);

            unless($dt)
            {
              $dt = Rose::DateTime::Util::parse_date($_[0], $tz || $db->server_time_zone) or
                Carp::croak "Invalid datetime: '$_[0]'";
            }

            $dt->set_time_zone($tz || $db->server_time_zone)  if(ref $dt);
            $self->{$key} = $dt;
            $self->{$formatted_key,$driver} = undef;

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
        my $dt = $db->$parse_method($default);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($default, $tz || $db->server_time_zone) or
            Carp::croak "Invalid default datetime: '$default'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
          $self->{$key} = $dt;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $dt;
        }

        $self->{$mod_columns_key}{$column_name} = 1
          unless($self->{STATE_IN_DB()});
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || $self->{$formatted_key,$driver}) ? 
          ($self->{$formatted_key,$driver} ||= $db->$format_method($self->{$key})) : undef;
      }

      return $self->{$key}   if($self->{$key});

      if(my $value = $self->{$formatted_key,$driver})
      {
        my $dt = $db->$parse_method($value);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($value, $tz || $db->server_time_zone) or
            Carp::croak "Invalid datetime: '$value'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
        }

        return $self->{$key} = $dt;
      }

      return undef;
    };
  }
  elsif($interface eq 'get')
  {
    $methods{$name} = sub
    {
      my $self = shift;

      my $db = $self->db or die "Missing Rose::DB object attribute";
      my $driver = $db->driver || 'unknown';

      if(@_ == 2)
      {
        my $dt = $self->{$key} || $self->{$formatted_key,$driver};

        if(defined $dt && !ref $dt)
        {
          my $dt2 = $db->parse_timestamp($dt);

          unless($dt2)
          {
            $dt2 = Rose::DateTime::Util::parse_date($dt, $tz || $db->server_time_zone, 1) or
              Carp::croak "Could not parse datetime '$dt'";
          }

          $dt = $dt2;
        }

        if($_[0] eq 'format')
        {
          return $dt  unless(ref $dt);
          return Rose::DateTime::Util::format_date($dt, (ref $_[1] ? @{$_[1]} : $_[1]), 1);
        }
        elsif($_[0] eq 'truncate')
        {
          return undef  unless($self->{$key});
          return $db->format_timestamp($dt)  unless(ref $dt);
          return $dt->clone->truncate(to => $_[1]);
        }
        else
        {
          Carp::croak "Invalid argument(s) to $name: @_";
        }
      }

      unless(!defined $default || defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
             ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
              ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
      {
        my $dt = $db->$parse_method($default);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($default, $tz || $db->server_time_zone) or
            Carp::croak "Invalid default datetime: '$default'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
          $self->{$key} = $dt;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $dt;
        }

        $self->{$mod_columns_key}{$column_name} = 1
          unless($self->{STATE_IN_DB()});
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || $self->{$formatted_key,$driver}) ? 
          ($self->{$formatted_key,$driver} ||= $db->$format_method($self->{$key})) : undef;
      }

      return $self->{$key}   if($self->{$key});

      if(my $value = $self->{$formatted_key,$driver})
      {
        my $dt = $db->$parse_method($value);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($value, $tz || $db->server_time_zone) or
            Carp::croak "Invalid datetime: '$value'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
        }

        return $self->{$key} = $dt;
      }

      return undef;
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
          my $dt = $db->$parse_method($_[0]);

          unless($dt)
          {
            $dt = Rose::DateTime::Util::parse_date($_[0], $tz || $db->server_time_zone) or
              Carp::croak "Invalid datetime: '$_[0]'";
          }

          $dt->set_time_zone($tz || $db->server_time_zone)  if(ref $dt);
          $self->{$key} = $dt;
          $self->{$formatted_key,$driver} = undef;

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

      return  unless(defined wantarray);

      unless(!defined $default || defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
             ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
              ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
      {
        my $dt = $db->$parse_method($default);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($default, $tz || $db->server_time_zone) or
            Carp::croak "Invalid default datetime: '$default'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
          $self->{$key} = $dt;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $dt;
        }

        $self->{$mod_columns_key}{$column_name} = 1
          unless($self->{STATE_IN_DB()});
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || $self->{$formatted_key,$driver}) ? 
          ($self->{$formatted_key,$driver} ||= $db->$format_method($self->{$key})) : undef;
      }

      return $self->{$key}   if($self->{$key});

      if(my $value = $self->{$formatted_key,$driver})
      {
        my $dt = $db->$parse_method($value);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($value, $tz || $db->server_time_zone) or
            Carp::croak "Invalid datetime: '$value'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
        }

        return $self->{$key} = $dt;
      }

      return undef;
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub timestamp_without_time_zone
{
  my($class, $name, $args) = @_;

  if(exists $args->{'time_zone'})
  {
    Carp::croak "time_zone parameter is invalid for timestamp_without_time_zone methods";
  }

  $args->{'time_zone'} = 'floating';

  return $class->timestamp($name, $args);
}

sub timestamp
{
  my($class, $name, $args) = @_;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';
  my $tz = $args->{'time_zone'} || 0;

  my $column_name = $args->{'column'} ? $args->{'column'}->name : $name;

  my $undef_overrides_default = $args->{'undef_overrides_default'} || 0;

  my $formatted_key = column_value_formatted_key($key);
  my $default = $args->{'default'};

  my $mod_columns_key = ($args->{'column'} ? $args->{'column'}->nonpersistent : 0) ? 
    MODIFIED_NP_COLUMNS : MODIFIED_COLUMNS;

  my $with_time_zone = $args->{'_with_time_zone'} ? 1 : 0;

  my $parse_method  = 'parse_timestamp' . ($with_time_zone ? '_with_time_zone' : '');
  my $format_method = 'format_timestamp' . ($with_time_zone ? '_with_time_zone' : '');

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
        if(@_ == 2)
        {
          my $dt = $self->{$key} || $self->{$formatted_key,$driver};

          if(defined $dt && !ref $dt)
          {
            my $dt2 = $db->$parse_method($dt);

            unless($dt2)
            {
              $dt2 = Rose::DateTime::Util::parse_date($dt, $tz || $db->server_time_zone, 1) or
                Carp::croak "Could not parse timestamp '$dt'";
            }

            $dt = $dt2;
          }

          if($_[0] eq 'format')
          {
            return $dt  unless(ref $dt);
            return Rose::DateTime::Util::format_date($dt, (ref $_[1] ? @{$_[1]} : $_[1]), 1);
          }
          elsif($_[0] eq 'truncate')
          {
            return undef  unless($self->{$key});
            return $db->$format_method($dt)  unless(ref $dt);
            return $dt->clone->truncate(to => $_[1]);
          }
          else
          {
            Carp::croak "Invalid argument(s) to $name: @_";
          }
        }

        if(defined $_[0])
        {
          if($self->{STATE_LOADING()})
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $_[0];
          }
          else
          {
            my $dt = $db->$parse_method($_[0]);

            unless($dt)
            {
              $dt = Rose::DateTime::Util::parse_date($_[0], $tz || $db->server_time_zone, 1) or
                Carp::croak "Invalid timestamp: '$_[0]'";
            }

            if(ref $dt)
            {
              if($with_time_zone)
              {
                $dt->set_time_zone($tz)  if($tz);
              }
              else
              {
                $dt->set_time_zone($tz || $db->server_time_zone);
              }
            }

            $self->{$key} = $dt;
            $self->{$formatted_key,$driver} = undef;

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
        my $dt = $db->$parse_method($default);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($default, $tz || $db->server_time_zone, 1) or
            Carp::croak "Invalid default timestamp: '$default'";
        }

        if(ref $dt)
        {
          if($with_time_zone)
          {
            $dt->set_time_zone($tz)  if($tz);
          }
          else
          {
            $dt->set_time_zone($tz || $db->server_time_zone);
          }

          $self->{$key} = $dt;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $dt;
        }

        $self->{$mod_columns_key}{$column_name} = 1
          unless($self->{STATE_IN_DB()});
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || $self->{$formatted_key,$driver}) ? 
          ($self->{$formatted_key,$driver} ||= $db->$format_method($self->{$key})) : undef;
      }

      return $self->{$key}   if($self->{$key});

      if(my $value = $self->{$formatted_key,$driver})
      {
        my $dt = $db->$parse_method($value);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($value, $tz || $db->server_time_zone) or
            Carp::croak "Invalid timestamp: '$value'";
        }

        if(ref $dt)
        {
          if($with_time_zone)
          {
            $dt->set_time_zone($tz)  if($tz);
          }
          else
          {
            $dt->set_time_zone($tz || $db->server_time_zone);
          }
        }

        return $self->{$key} = $dt;
      }

      return undef;
    };
  }
  elsif($interface eq 'get')
  {
    $methods{$name} = sub
    {
      my $self = shift;

      my $db = $self->db or die "Missing Rose::DB object attribute";
      my $driver = $db->driver || 'unknown';

      if(@_ == 2)
      {
        my $dt = $self->{$key} || $self->{$formatted_key,$driver};

        if(defined $dt && !ref $dt)
        {
          my $dt2 = $db->$parse_method($dt);

          unless($dt2)
          {
            $dt2 = Rose::DateTime::Util::parse_date($dt, $tz || $db->server_time_zone, 1) or
              Carp::croak "Could not parse timestamp '$dt'";
          }

          $dt = $dt2;
        }

        if($_[0] eq 'format')
        {
          return $dt  unless(ref $dt);
          return Rose::DateTime::Util::format_date($dt, (ref $_[1] ? @{$_[1]} : $_[1]), 1);
        }
        elsif($_[0] eq 'truncate')
        {
          return undef  unless($self->{$key});
          return $db->$format_method($dt)  unless(ref $dt);
          return $dt->clone->truncate(to => $_[1]);
        }
        else
        {
          Carp::croak "Invalid argument(s) to $name: @_";
        }
      }

      return  unless(defined wantarray);

      unless(!defined $default || defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
             ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
              ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
      {
        my $dt = $db->$parse_method($default);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($default, $tz || $db->server_time_zone, 1) or
            Carp::croak "Invalid default timestamp: '$default'";
        }

        if(ref $dt)
        {
          if($with_time_zone)
          {
            $dt->set_time_zone($tz)  if($tz);
          }
          else
          {
            $dt->set_time_zone($tz || $db->server_time_zone);
          }

          $self->{$key} = $dt;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $dt;
        }

        $self->{$mod_columns_key}{$column_name} = 1
          unless($self->{STATE_IN_DB()});
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || $self->{$formatted_key,$driver}) ? 
          ($self->{$formatted_key,$driver} ||= $db->$format_method($self->{$key})) : undef;
      }

      return $self->{$key}   if($self->{$key});

      if(my $value = $self->{$formatted_key,$driver})
      {
        my $dt = $db->$parse_method($value);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($value, $tz || $db->server_time_zone) or
            Carp::croak "Invalid timestamp: '$value'";
        }

        if(ref $dt)
        {
          if($with_time_zone)
          {
            $dt->set_time_zone($tz)  if($tz);
          }
          else
          {
            $dt->set_time_zone($tz || $db->server_time_zone);
          }
        }

        return $self->{$key} = $dt;
      }

      return undef;
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
          my $dt = $db->$parse_method($_[0]);

          unless($dt)
          {
            $dt = Rose::DateTime::Util::parse_date($_[0], $tz || $db->server_time_zone, 1) or
              Carp::croak "Invalid timestamp: '$_[0]'";
          }

          if(ref $dt)
          {
            if($with_time_zone)
            {
              $dt->set_time_zone($tz)  if($tz);
            }
            else
            {
              $dt->set_time_zone($tz || $db->server_time_zone);
            }
          }

          $self->{$key} = $dt;
          $self->{$formatted_key,$driver} = undef;

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

      return  unless(defined wantarray);

      unless(!defined $default || defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
             ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
              ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
      {
        my $dt = $db->$parse_method($default);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($default, $tz || $db->server_time_zone, 1) or
            Carp::croak "Invalid default timestamp: '$default'";
        }

        if(ref $dt)
        {
          if($with_time_zone)
          {
            $dt->set_time_zone($tz)  if($tz);
          }
          else
          {
            $dt->set_time_zone($tz || $db->server_time_zone);
          }

          $self->{$key} = $dt;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $dt;
        }

        $self->{$mod_columns_key}{$column_name} = 1
          unless($self->{STATE_IN_DB()});
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || $self->{$formatted_key,$driver}) ? 
          ($self->{$formatted_key,$driver} ||= $db->$format_method($self->{$key})) : undef;
      }

      return $self->{$key}  if($self->{$key});

      if(my $value = $self->{$formatted_key,$driver})
      {
        my $dt = $db->$parse_method($value);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_date($value, $tz || $db->server_time_zone) or
            Carp::croak "Invalid timestamp: '$value'";
        }

        if(ref $dt)
        {
          if($with_time_zone)
          {
            $dt->set_time_zone($tz)  if($tz);
          }
          else
          {
            $dt->set_time_zone($tz || $db->server_time_zone);
          }
        }

        return $self->{$key} = $dt;
      }

      return undef;
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub timestamp_with_time_zone
{
  my($class, $name, $args) = @_;
  $args->{'_with_time_zone'} = 1;
  return shift->timestamp(@_);
}

sub epoch
{
  my($class, $name, $args) = @_;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';
  my $tz = $args->{'time_zone'} || 0;
  my $epoch_method = $args->{'hires'} ? 'hires_epoch' : 'epoch';

  my $column_name = $args->{'column'} ? $args->{'column'}->name : $name;

  my $undef_overrides_default = $args->{'undef_overrides_default'} || 0;

  my $formatted_key = column_value_formatted_key($key);
  my $default = $args->{'default'};

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
        if(@_ == 2)
        {
          my $dt = $self->{$key} || $self->{$formatted_key,$driver};

          if(defined $dt && !ref $dt)
          {
            my $dt2 = $db->parse_date($dt);

            unless($dt2)
            {
              $dt2 = Rose::DateTime::Util::parse_epoch($dt, $tz || $db->server_time_zone) or
                Carp::croak "Could not parse date '$dt'";
            }

            $dt = $dt2;
          }

          if($_[0] eq 'format')
          {
            return $dt  unless(ref $dt);
            return Rose::DateTime::Util::format_date($dt, (ref $_[1] ? @{$_[1]} : $_[1]));
          }
          elsif($_[0] eq 'truncate')
          {
            return undef  unless($self->{$key});
            return $dt  unless(ref $dt);
            return $dt->clone->truncate(to => $_[1]);
          }
          else
          {
            Carp::croak "Invalid argument(s) to $name: @_";
          }
        }

        if(defined $_[0])
        {
          if($self->{STATE_LOADING()})
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $_[0];
          }
          else
          {
            my $dt = $db->parse_date($_[0]);

            unless($dt)
            {
              $dt = Rose::DateTime::Util::parse_epoch($_[0], $tz || $db->server_time_zone) or
                Carp::croak "Invalid date: '$_[0]'";
            }

            if(ref $dt)
            {
              $dt->set_time_zone($tz || $db->server_time_zone);
              $self->{$key} = $dt;
              $self->{$formatted_key,$driver} = undef;
            }
            else
            {
              $self->{$key} = undef;
              $self->{$formatted_key,$driver} = $dt;
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
        my $dt = $db->parse_date($default);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_epoch($default, $tz || $db->server_time_zone) or
            Carp::croak "Invalid default epoch: '$default'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
          $self->{$key} = $dt;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $dt;
        }

        $self->{$mod_columns_key}{$column_name} = 1
          unless($self->{STATE_IN_DB()});
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || defined $self->{$formatted_key,$driver}) ? 
          (defined $self->{$formatted_key,$driver} ? 
           $self->{$formatted_key,$driver} :
           ($self->{$formatted_key,$driver} = $self->{$key}->$epoch_method())) : undef;
      }

      return $self->{$key}   if($self->{$key});

      if(defined(my $value = $self->{$formatted_key,$driver}))
      {
        my $dt = $db->parse_date($value);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_epoch($value, $tz || $db->server_time_zone) or
            Carp::croak "Invalid epoch: '$value'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
        }

        return $self->{$key} = $dt;
      }

      return undef;
    };
  }
  elsif($interface eq 'get')
  {
    $methods{$name} = sub
    {
      my $self = shift;

      my $db = $self->db or die "Missing Rose::DB object attribute";
      my $driver = $db->driver || 'unknown';

      if(@_ == 2)
      {
        my $dt = $self->{$key} || $self->{$formatted_key,$driver};

        if(defined $dt && !ref $dt)
        {
          my $dt2 = $db->parse_date($dt);

          unless($dt2)
          {
            $dt2 = Rose::DateTime::Util::parse_epoch($dt, $tz || $db->server_time_zone) or
              Carp::croak "Could not parse date '$dt'";
          }

          $dt = $dt2;
        }

        if($_[0] eq 'format')
        {
          return $dt  unless(ref $dt);
          return Rose::DateTime::Util::format_date($dt, (ref $_[1] ? @{$_[1]} : $_[1]));
        }
        elsif($_[0] eq 'truncate')
        {
          return undef  unless($self->{$key});
          return $dt  unless(ref $dt);
          return $dt->clone->truncate(to => $_[1]);
        }
        else
        {
          Carp::croak "Invalid argument(s) to $name: @_";
        }
      }

      return  unless(defined wantarray);

      unless(!defined $default || defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
             ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
              ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
      {
        my $dt = $db->parse_date($default);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_epoch($default, $tz || $db->server_time_zone) or
            Carp::croak "Invalid default epoch: '$default'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
          $self->{$key} = $dt;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $dt;
        }

        $self->{$mod_columns_key}{$column_name} = 1
          unless($self->{STATE_IN_DB()});
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || defined $self->{$formatted_key,$driver}) ? 
          (defined $self->{$formatted_key,$driver} ? 
           $self->{$formatted_key,$driver} : 
           ($self->{$formatted_key,$driver} = $self->{$key}->$epoch_method())) : undef;
      }

      return $self->{$key}   if($self->{$key});

      if(defined(my $value = $self->{$formatted_key,$driver}))
      {
        my $dt = $db->parse_date($value);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_epoch($value, $tz || $db->server_time_zone) or
            Carp::croak "Invalid epoch: '$value'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
        }

        return $self->{$key} = $dt;
      }

      return undef;
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
          my $dt = $db->parse_date($_[0]);

          unless($dt)
          {
            $dt = Rose::DateTime::Util::parse_epoch($_[0], $tz || $db->server_time_zone) or
              Carp::croak "Invalid date: '$_[0]'";
          }

          if(ref $dt)
          {
            $dt->set_time_zone($tz || $db->server_time_zone);
            $self->{$key} = $dt;
            $self->{$formatted_key,$driver} = undef;
          }
          else
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $dt;
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
        my $dt = $db->parse_date($default);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_epoch($default, $tz || $db->server_time_zone) or
            Carp::croak "Invalid default epoch: '$default'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
          $self->{$key} = $dt;
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $dt;
        }
      }

      if($self->{STATE_SAVING()})
      {
        return ($self->{$key} || defined $self->{$formatted_key,$driver}) ? 
          (defined $self->{$formatted_key,$driver} ?
           $self->{$formatted_key,$driver} :
           ($self->{$formatted_key,$driver} = $self->{$key}->$epoch_method())) : undef;
      }

      return $self->{$key}   if($self->{$key});

      if(defined(my $value = $self->{$formatted_key,$driver}))
      {
        my $dt = $db->parse_date($value);

        unless($dt)
        {
          $dt = Rose::DateTime::Util::parse_epoch($value, $tz || $db->server_time_zone) or
            Carp::croak "Invalid epoch: '$value'";
        }

        if(ref $dt)
        {
          $dt->set_time_zone($tz || $db->server_time_zone);
        }

        return $self->{$key} = $dt;
      }

      return undef;
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

1;

__END__

=head1 NAME

Rose::DB::Object::MakeMethods::Date - Create date-related methods for Rose::DB::Object-derived objects.

=head1 SYNOPSIS

    package MyDBObject;

    use base 'Rose::DB::Object';

    use Rose::DB::Object::MakeMethods::Date
    (
      date => 
      [
        'start_date',
        'end_date' => { default => '2005-01-30' }
      ],

      datetime => 
      [
        'date_created',
        'other_date' => { type => 'datetime year to minute' },
      ],

      timestamp => 
      [
        'last_modified' => { default => '2005-01-30 12:34:56.123' }
      ],

      epoch => 
      [
        due_date    => { default => '2003-01-02 12:34:56' },
        event_start => { hires => 1 },
      ],
    );

    ...

    $o->start_date('2/3/2004 8am');
    $dt = $o->start_date(truncate => 'day');

    print $o->end_date(format => '%m/%d/%Y'); # 2005-01-30

    $o->date_created('now');

    $o->other_date('2001-02-20 12:34:56');

    # 02/20/2001 12:34:00
    print $o->other_date(format => '%m/%d/%Y %H:%M:%S'); 

    print $o->last_modified(format => '%S.%5N'); # 56.12300 

    print $o->due_date(format => '%m/%d/%Y'); # 01/02/2003

    $o->event_start('1980-10-11 6:00.123456');

=head1 DESCRIPTION

C<Rose::DB::Object::MakeMethods::Date> creates methods that deal with dates, and inherits from L<Rose::Object::MakeMethods>.  See the L<Rose::Object::MakeMethods> documentation to learn about the interface.  The method types provided by this module are described below.

All method types defined by this module are designed to work with objects that are subclasses of (or otherwise conform to the interface of) L<Rose::DB::Object>.  In particular, the object is expected to have a L<db|Rose::DB::Object/db> method that returns a L<Rose::DB>-derived object.  See the L<Rose::DB::Object> documentation for more details.

=head1 METHODS TYPES

=over 4

=item B<date>

Create get/set methods for date (year, month, day) attributes.

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

=item C<time_zone>

The time zone name, which must be in a format that is understood by L<DateTime::TimeZone>.

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a get/set method for a date (year, month, day) attribute.  When setting the attribute, the value is passed through the L<parse_date|Rose::DB/parse_date> method of the object's L<db|Rose::DB::Object/db> attribute.  If that fails, the value is passed to L<Rose::DateTime::Util>'s L<parse_date()|Rose::DateTime::Util/parse_date> function.  If that fails, a fatal error will occur.

The time zone of the L<DateTime> object that results from a successful parse is set to the value of the C<time_zone> option, if defined.  Otherwise, it is set to the L<server_time_zone|Rose::DB/server_time_zone> value of the  object's L<db|Rose::DB::Object/db> attribute using L<DateTime>'s L<set_time_zone|DateTime/set_time_zone> method.

When saving to the database, the method will pass the attribute value through the L<format_date|Rose::DateTime::Util/format_date> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.  Otherwise, the value is returned as-is.

This method is designed to allow date values to make a round trip from and back into the database without ever being "inflated" into L<DateTime> objects.  Any use of the attribute (get or set) outside the context of loading from or saving to the database will cause the value to be "inflated" using the  L<parse_date|Rose::DB/parse_date> method of the object's L<db|Rose::DB::Object/db> attribute.  If that fails, L<Rose::DateTime::Util>'s L<parse_date()|Rose::DateTime::Util/parse_date> function is tried.  If that fails, a fatal error will occur.

If passed two arguments and the first argument is "format", then the second argument is taken as a format string and passed to L<Rose::DateTime::Util>'s L<format_date|Rose::DateTime::Util/format_date> function along with the current value of the date attribute.  Example:

    $o->start_date('2004-05-22');
    print $o->start_date(format => '%A'); # "Saturday"

If passed two arguments and the first argument is "truncate", then the second argument is taken as the value of the C<to> argument to L<DateTime>'s L<truncate|DateTime/truncate> method, which is applied to a clone of the current value of the date attribute, which is then returned.  Example:

    $o->start_date('2004-05-22');

    # Equivalent to: 
    # $d = $o->start_date->clone->truncate(to => 'month')
    $d = $o->start_date(truncate => 'month');

If the date attribute is undefined, then undef is returned (i.e., no clone or call to L<truncate|DateTime/truncate> is made).

If a valid date keyword is passed as an argument, the value will never be "inflated" but rather passed to the database I<and> returned to other code unmodified.  That means that the "truncate" and "format" calls described above will also return the date keyword unmodified.  See the L<Rose::DB> documentation for more information on date keywords.

=item C<get>

Creates an accessor method for a date (year, month, day) attribute.  This method behaves like the C<get_set> method, except that the value cannot be set. 

=item C<set>

Creates a mutator method for a date (year, month, day) attribute.  This method behaves like the C<get_set> method, except that a fatal error will occur if no arguments are passed.  It also does not support the C<truncate> and C<format> parameters.

=back

=back

Example:

    package MyDBObject;

    use base 'Rose::DB::Object';

    use Rose::DB::Object::MakeMethods::Date
    (
      date => 
      [
        'start_date',
        'end_date' => { default => '2005-01-30' }
      ],
    );

    ...

    $o->start_date('2/3/2004');
    $dt = $o->start_date(truncate => 'week');

    print $o->end_date(format => '%m/%d/%Y'); # 01/30/2005

=item B<datetime>

Create get/set methods for "datetime" (year, month, day, hour, minute, second) attributes.

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

=item C<time_zone>

The time zone name, which must be in a format that is understood by L<DateTime::TimeZone>.

=item C<type>

The datetime variant as a string.  Each space in the string is replaced with an underscore "_", then the string is appended to "format_" and "parse_" in order to form the names of the methods called on the object's L<db|Rose::DB::Object/db> attribute to format and parse datetime values.  The default is "datetime", which means that the C<format_datetime()> and C<parse_datetime()> methods will be used.

Any string that results in a set of method names that are supported by the object's L<db|Rose::DB::Object/db> attribute is acceptable.  Check the documentation for the class of the object's L<db|Rose::DB::Object/db> attribute for a list of valid method names.

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a get/set method for a "datetime" attribute.  The exact granularity of the "datetime" value is determined by the value of the C<type> option (see above).

When setting the attribute, the value is passed through the C<parse_TYPE()> method of the object's L<db|Rose::DB::Object/db> attribute, where C<TYPE> is the value of the C<type> option.  If that fails, the value is passed to L<Rose::DateTime::Util>'s L<parse_date()|Rose::DateTime::Util/parse_date> function.  If that fails, a fatal error will occur.

The time zone of the L<DateTime> object that results from a successful parse is set to the value of the C<time_zone> option, if defined.  Otherwise, it is set to the L<server_time_zone|Rose::DB/server_time_zone> value of the  object's L<db|Rose::DB::Object/db> attribute using L<DateTime>'s L<set_time_zone|DateTime/set_time_zone> method.

When saving to the database, the method will pass the attribute value through the C<format_TYPE()> method of the object's L<db|Rose::DB::Object/db> attribute before returning it, where C<TYPE> is the value of the C<type> option.  Otherwise, the value is returned as-is.

This method is designed to allow datetime values to make a round trip from and back into the database without ever being "inflated" into L<DateTime> objects.  Any use of the attribute (get or set) outside the context of loading from or saving to the database will cause the value to be "inflated" using the  C<parse_TYPE()> method of the object's L<db|Rose::DB::Object/db> attribute, where C<TYPE> is the value of the C<type> option.  If that fails, L<Rose::DateTime::Util>'s L<parse_date()|Rose::DateTime::Util/parse_date> function is tried.  If that fails, a fatal error will occur.

If passed two arguments and the first argument is "format", then the second argument is taken as a format string and passed to L<Rose::DateTime::Util>'s L<format_date|Rose::DateTime::Util/format_date> function along with the current value of the datetime attribute.  Example:

    $o->start_date('2004-05-22 12:34:56');
    print $o->start_date(format => '%A'); # "Saturday"

If passed two arguments and the first argument is "truncate", then the second argument is taken as the value of the C<to> argument to L<DateTime>'s L<truncate|DateTime/truncate> method, which is applied to a clone of the current value of the datetime attribute, which is then returned.  Example:

    $o->start_date('2004-05-22 04:32:01');

    # Equivalent to: 
    # $d = $o->start_date->clone->truncate(to => 'month')
    $d = $o->start_date(truncate => 'month');

If the datetime attribute is undefined, then undef is returned (i.e., no clone or call to L<truncate|DateTime/truncate> is made).

If a valid datetime keyword is passed as an argument, the value will never be "inflated" but rather passed to the database I<and> returned to other code unmodified.  That means that the "truncate" and "format" calls described above will also return the datetime keyword unmodified.  See the L<Rose::DB> documentation for more information on datetime keywords.

=item C<get>

Creates an accessor method for a "datetime" attribute.  This method behaves like the C<get_set> method, except that the value cannot be set. 

=item C<set>

Creates a mutator method for a "datetime" attribute.  This method behaves like the C<get_set> method, except that a fatal error will occur if no arguments are passed.  It also does not support the C<truncate> and C<format> parameters.

=back

=back

Example:

    package MyDBObject;

    use base 'Rose::DB::Object';

    use Rose::DB::Object::MakeMethods::Date
    (
      datetime => 
      [
        'start_date',
        'end_date'   => { default => '2005-01-30 12:34:56' }
        'other_date' => { type => 'datetime year to minute' },
      ],
    );

    ...

    $o->start_date('2/3/2004 8am');
    $dt = $o->start_date(truncate => 'day');

    # 01/30/2005 12:34:56
    print $o->end_date(format => '%m/%d/%Y %H:%M:%S'); 

    $o->other_date('2001-02-20 12:34:56');

    # 02/20/2001 12:34:00
    print $o->other_date(format => '%m/%d/%Y %H:%M:%S'); 

=item B<epoch>

Create get/set methods for an attribute that stores seconds since the Unix epoch.

=over 4

=item Options

=over 4

=item C<default>

Determines the default value of the attribute.

=item C<hash_key>

The key inside the hash-based object to use for the storage of this
attribute.  Defaults to the name of the method.

=item C<hires>

A boolean flag that indicates whether or not epoch values should be stored with fractional seconds.  If true, then up to six (6) digits past the decimal point are preserved.  The default is false.

=item C<interface>

Choose the interface.  The default is C<get_set>.

=item C<time_zone>

The time zone name, which must be in a format that is understood by L<DateTime::TimeZone>.

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a get/set method for an attribute that stores seconds since the Unix epoch.  When setting the attribute, the value is passed through L<Rose::DateTime::Util>'s L<parse_date()|Rose::DateTime::Util/parse_date> function.  If that fails, a fatal error will occur.

The time zone of the L<DateTime> object that results from a successful parse is set to the value of the C<time_zone> option, if defined.  Otherwise, it is set to the L<server_time_zone|Rose::DB/server_time_zone> value of the  object's L<db|Rose::DB::Object/db> attribute using L<DateTime>'s L<set_time_zone|DateTime/set_time_zone> method.

When saving to the database, the L<epoch|DateTime/epoch> or L<hires_epoch|DateTime/hires_epoch> method will be called on the L<DateTime> object, depending on the value of the C<hires> option.  (See above.)

This method is designed to allow values to make a round trip from and back into the database without ever being "inflated" into L<DateTime> objects.  Any use of the attribute (get or set) outside the context of loading from or saving to the database will cause the value to be "inflated" using L<Rose::DateTime::Util>'s L<parse_date()|Rose::DateTime::Util/parse_date> function.  If that fails, a fatal error will occur.

If passed two arguments and the first argument is "format", then the second argument is taken as a format string and passed to L<Rose::DateTime::Util>'s L<format_date|Rose::DateTime::Util/format_date> function along with the current value of the attribute.  Example:

    $o->due_date('2004-05-22');
    print $o->due_date(format => '%A'); # "Saturday"

If passed two arguments and the first argument is "truncate", then the second argument is taken as the value of the C<to> argument to L<DateTime>'s L<truncate|DateTime/truncate> method, which is applied to a clone of the current value of the attribute, which is then returned.  Example:

    $o->due_date('2004-05-22');

    # Equivalent to: 
    # $d = $o->due_date->clone->truncate(to => 'month')
    $d = $o->due_date(truncate => 'month');

If the attribute is undefined, then undef is returned (i.e., no clone or call to L<truncate|DateTime/truncate> is made).

=item C<get>

Creates an accessor method an attribute that stores seconds since the Unix epoch.  This method behaves like the C<get_set> method, except that the value cannot be set. 

=item C<set>

Creates a mutator method for an attribute that stores seconds since the Unix epoch.  This method behaves like the C<get_set> method, except that a fatal error will occur if no arguments are passed.  It also does not support the C<truncate> and C<format> parameters.

=back

=back

Example:

    package MyDBObject;

    use base 'Rose::DB::Object';

    use Rose::DB::Object::MakeMethods::Date
    (
      epoch => 
      [
        due_date    => { default => '2003-01-02 12:34:56' },
        event_start => { hires => 1 },
      ],
    );

    ...

    print $o->due_date(format => '%m/%d/%Y'); # 01/02/2003
    $dt = $o->due_date(truncate => 'week');

    $o->event_start('1980-10-11 6:00.123456');
    print $o->event_start(format => '%6N'); # 123456

=item B<timestamp>

Create get/set methods for "timestamp" (year, month, day, hour, minute, second, fractional seconds) attributes.

=over 4

=item Options

=over 4

=item C<default>

Determines the default value of the attribute.

=item C<hash_key>

The key inside the hash-based object to use for the storage of this
attribute.  Defaults to the name of the method.

=item C<interface>

Choose the interface.  The default interface is C<get_set>.

=item C<time_zone>

A time zone name, which must be in a format that is understood by L<DateTime::TimeZone>.

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a get/set method for a "timestamp" (year, month, day, hour, minute, second, fractional seconds) attribute.  When setting the attribute, the value is passed through the C<parse_timestamp()> method of the object's L<db|Rose::DB::Object/db> attribute.  If that fails, the value is passed to L<Rose::DateTime::Util>'s L<parse_date()|Rose::DateTime::Util/parse_date> function.  If that fails, a fatal error will occur.

The time zone of the L<DateTime> object that results from a successful parse is set to the value of the C<time_zone> option, if defined.  Otherwise, it is set to the L<server_time_zone|Rose::DB/server_time_zone> value of the  object's L<db|Rose::DB::Object/db> attribute using L<DateTime>'s L<set_time_zone|DateTime/set_time_zone> method.

When saving to the database, the method will pass the attribute value through the L<format_timestamp|Rose::DB/format_timestamp> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.  Otherwise, the value is returned as-is.

This method is designed to allow timestamp values to make a round trip from and back into the database without ever being "inflated" into L<DateTime> objects.  Any use of the attribute (get or set) outside the context of loading from or saving to the database will cause the value to be "inflated" using the  C<parse_timestamp()> method of the object's L<db|Rose::DB::Object/db> attribute.  If that fails, L<Rose::DateTime::Util>'s L<parse_date()|Rose::DateTime::Util/parse_date> function is tried.  If that fails, a fatal error will occur.

If passed two arguments and the first argument is "format", then the second argument is taken as a format string and passed to L<Rose::DateTime::Util>'s L<format_date|Rose::DateTime::Util/format_date> function along with the current value of the timestamp attribute.  Example:

    $o->start_date('2004-05-22 12:34:56.123');
    print $o->start_date(format => '%A'); # "Saturday"

If passed two arguments and the first argument is "truncate", then the second argument is taken as the value of the C<to> argument to L<DateTime>'s L<truncate|DateTime/truncate> method, which is applied to a clone of the current value of the timestamp attribute, which is then returned.  Example:

    $o->start_date('2004-05-22 04:32:01.456');

    # Equivalent to: 
    # $d = $o->start_date->clone->truncate(to => 'month')
    $d = $o->start_date(truncate => 'month');

If the timestamp attribute is undefined, then undef is returned (i.e., no clone or call to L<truncate|DateTime/truncate> is made).

If a valid timestamp keyword is passed as an argument, the value will never be "inflated" but rather passed to the database I<and> returned to other code unmodified.  That means that the "truncate" and "format" calls described above will also return the timestamp keyword unmodified.  See the L<Rose::DB> documentation for more information on timestamp keywords.

=item C<get>

Creates an accessor method for a "timestamp" (year, month, day, hour, minute, second, fractional seconds) attribute.  This method behaves like the C<get_set> method, except that the value cannot be set. 

=item C<set>

Creates a mutator method for a "timestamp" (year, month, day, hour, minute, second, fractional seconds) attribute.  This method behaves like the C<get_set> method, except that a fatal error will occur if no arguments are passed.  It also does not support the C<truncate> and C<format> parameters.

=back

=back

Example:

    package MyDBObject;

    use base 'Rose::DB::Object';

    use Rose::DB::Object::MakeMethods::Date
    (
      timestamp => 
      [
        'start_date',
        'end_date' => { default => '2005-01-30 12:34:56.123' }
      ],
    );

    ...

    $o->start_date('2/3/2004 8am');
    $dt = $o->start_date(truncate => 'day');

    # 01/30/2005 12:34:56.12300
    print $o->end_date(format => '%m/%d/%Y %H:%M:%S.%5N');

=item B<timestamp_without_time_zone>

This is identical to the L<timestamp|/timestamp> method described above, but with the C<time_zone> parameter always set to the value "floating".  Any attempt to set the C<time_zone> parameter explicitly will cause a fatal error.

=item B<timestamp_with_time_zone>

Create get/set methods for "timestamp with time zone" (year, month, day, hour, minute, second, fractional seconds, time zone) attributes.

=over 4

=item Options

=over 4

=item C<default>

Determines the default value of the attribute.

=item C<hash_key>

The key inside the hash-based object to use for the storage of this
attribute.  Defaults to the name of the method.

=item C<interface>

Choose the interface.  The default interface is C<get_set>.

=item C<time_zone>

A time zone name, which must be in a format that is understood by L<DateTime::TimeZone>.

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a get/set method for a "timestamp with time zone" (year, month, day, hour, minute, second, fractional seconds, time zone) attribute.  When setting the attribute, the value is passed through the C<parse_timestamp_with_timezone()> method of the object's L<db|Rose::DB::Object/db> attribute.  If that fails, the value is passed to L<Rose::DateTime::Util>'s L<parse_date()|Rose::DateTime::Util/parse_date> function.  If that fails, a fatal error will occur.

The time zone of the L<DateTime> object will be set according to the successful parse of the "timestamp with time zone" value.  If the C<time_zone> option is set, then the time zone of the L<DateTime> object is set to this value.  Note that this happens I<after> the successful parse, which means that this operation may change the time and/or date according to the difference between the time zone of the value as originally parsed and the new time zone set according to the C<time_zone> option.

When saving to the database, the method will pass the attribute value through the L<format_timestamp_with_timezone|Rose::DB/format_timestamp_with_timezone> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.  Otherwise, the value is returned as-is.

This method is designed to allow timestamp values to make a round trip from and back into the database without ever being "inflated" into L<DateTime> objects.  Any use of the attribute (get or set) outside the context of loading from or saving to the database will cause the value to be "inflated" using the  C<parse_timestamp_with_time_zone()> method of the object's L<db|Rose::DB::Object/db> attribute.  If that fails, L<Rose::DateTime::Util>'s L<parse_date()|Rose::DateTime::Util/parse_date> function is tried.  If that fails, a fatal error will occur.

If passed two arguments and the first argument is "format", then the second argument is taken as a format string and passed to L<Rose::DateTime::Util>'s L<format_date|Rose::DateTime::Util/format_date> function along with the current value of the timestamp attribute.  Example:

    $o->start_date('2004-05-22 12:34:56.123');
    print $o->start_date(format => '%A'); # "Saturday"

If passed two arguments and the first argument is "truncate", then the second argument is taken as the value of the C<to> argument to L<DateTime>'s L<truncate|DateTime/truncate> method, which is applied to a clone of the current value of the timestamp attribute, which is then returned.  Example:

    $o->start_date('2004-05-22 04:32:01.456');

    # Equivalent to: 
    # $d = $o->start_date->clone->truncate(to => 'month')
    $d = $o->start_date(truncate => 'month');

If the timestamp attribute is undefined, then undef is returned (i.e., no clone or call to L<truncate|DateTime/truncate> is made).

If a valid timestamp keyword is passed as an argument, the value will never be "inflated" but rather passed to the database I<and> returned to other code unmodified.  That means that the "truncate" and "format" calls described above will also return the timestamp keyword unmodified.  See the L<Rose::DB> documentation for more information on timestamp keywords.

=item C<get>

Creates an accessor method for a "timestamp with time zone" (year, month, day, hour, minute, second, fractional seconds, time zone) attribute.  This method behaves like the C<get_set> method, except that the value cannot be set. 

=item C<set>

Creates a mutator method for a "timestamp with time zone" (year, month, day, hour, minute, second, fractional seconds, time zone) attribute.  This method behaves like the C<get_set> method, except that a fatal error will occur if no arguments are passed.  It also does not support the C<truncate> and C<format> parameters.

=back

=back

Example:

    package MyDBObject;

    use base 'Rose::DB::Object';

    use Rose::DB::Object::MakeMethods::Date
    (
      timestamp_with_timezone => 
      [
        'start_date',
        'end_date' => { default => '2005-01-30 12:34:56.123' }
      ],
    );

    ...

    $o->start_date('2/3/2004 8am');
    $dt = $o->start_date(truncate => 'day');

    # 01/30/2005 12:34:56.12300
    print $o->end_date(format => '%m/%d/%Y %H:%M:%S.%5N');

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
