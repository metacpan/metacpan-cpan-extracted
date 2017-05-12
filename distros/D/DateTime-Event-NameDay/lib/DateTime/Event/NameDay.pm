package DateTime::Event::NameDay;

use strict;

use vars qw ($VERSION);

$VERSION = '0.02';

use Carp;
use Params::Validate qw( validate SCALAR OBJECT HASHREF );

use DateTime;
use DateTime::Set;
use DateTime::Calendar::Christian;


my %namedays = ();


sub new {
    my $class = shift;
    my %p = validate( @_,
		      { country   => { type      => SCALAR,
				       default   => undef,
				       # Leave the heavy validation to set
				     },
			date_args => { type      => HASHREF,
				       default   => {},
				     },
		       },
		      );
    my $self = { };
    bless $self, $class;
    $self->set( %p );

    return $self;
}

sub set {
    my $self = shift;

    my %p = validate( @_,
                      { country   => { type      => SCALAR,
				       optional  => 1,
				       callbacks => 
				           {'known day mapping' => \&_check_country }
				     },
			date_args => { type      => HASHREF,
				       default   => {},
				     },
		      }
		      );

    if (defined $p{country}) {
	$self->{country} = lc $p{country};
    }

    if (defined $p{date_args}) {
	$self->{date_args} = $p{date_args};
    }

    return $self;
}

sub country {
    my ($self) = @_;
    return undef unless ref $self;
    return $self->{country};
}


sub date_args {
    my ($self) = @_;
    return {} unless ref $self;
    return $self->{date_args};
}

sub get_daynames
{
    my $self = shift;
    my %p = validate( @_,
                      { country => { type      => SCALAR,
				     optional  => 1,
				     callbacks => 
				           {'known day mapping' => \&_check_country }
				     },
			date    => { type      => OBJECT,
				     can       => 'utc_rd_values',
				     },
		      }
		      );

    # Work out our country
    my $country = lc $p{country};
    if (not defined $country) {
	$country = $self->country();

	croak "Unable to determine the correct country"
	    unless defined $country;
    }

    # Get the namedays for the given date
    # - Find our section
    my $nameday_info = 
	$self->_init_nameday_country(namedays => \%namedays,
				     country  => $country);

    # - Convert to the Julian calendar
    my $adj_dt = DateTime::Calendar::Christian->from_object
	(object      => $p{date},
	 reform_date => $nameday_info->{reform_date},
	 %{ $self->date_args() },
	 );
    
    # - Get the appropriate nameday based on month number and day
    my $names = $nameday_info->{names}{ $adj_dt->month() }{ $adj_dt->day() };
    my @names = defined $names ? @$names : ();

    return @names;
}

sub get_namedays {
    my $self = shift;
    my %p = validate( @_,
                      { country => { type      => SCALAR,
				     optional  => 1,
				     callbacks => 
				           {'known day mapping' => \&_check_country }
				     },
			date_args => { type      => HASHREF,
				       default   => undef,
				     },
			name    => { type      => SCALAR,
				     },
		      }
		      );

    # Work out our country
    my $country = lc $p{country};
    if (not defined $country) {
	$country = $self->country();

	croak "Unable to determine the correct country"
	    unless defined $country;
    }

    # Work out the date args
    my $date_args = $p{date_args};
    if (not defined $date_args) {
	$date_args = ref $self ? $self->date_args() : {};
    }

    # Get the canonical name
    my $name = _clean_name( $p{name} );

    # Find the month and day for the given name
    my $nameday_info = 
	$self->_init_nameday_country(namedays => \%namedays,
				     country  => $country);
    croak "Unknown name '$p{name}' for country '$p{country}'"
	unless exists $nameday_info->{reverse_names}{$name};
    my ($month, $day) = @{ $nameday_info->{reverse_names}{$name} };

    # Build a set of all of the days that the given name is for
    my $set = DateTime::Set->from_recurrence
	(next => 
	     sub { _make_recurrence($_[0], $nameday_info->{reform_date},
					   $month, $day, 1, $date_args);
	     },
	 previous => 
	     sub { _make_recurrence($_[0], $nameday_info->{reform_date},
					   $month, $day, -1, $date_args);
	     },
	 );

    return $set;
}

sub _make_recurrence {
    my ($last, $reform_date, $month, $day, $direction, $date_args) = @_;

    my $dt = DateTime::Calendar::Christian->from_object
	(object      => $last,
	 reform_date => $reform_date,
	 %$date_args,
	 );
    $dt->truncate(to => 'day');
    my $target = $dt->clone();
    $target->set( month => $month,
		  day   => $day,
		  );
    
    if ($direction == 1) {
	if ($dt >= $target) {
	    $target->add( years => 1);
	}
    } else {
	if ($dt <= $target) {
	    $target->subtract( years => 1);
	}
    }

    $target->set( month => $month,
		  day   => $day,
		  );

    return DateTime->from_object(object => $target, %$date_args);
}

sub _init_nameday_country {
    my $self = shift;
    my %args = @_;
    my $country  = $args{country};
    my $namedays = $args{namedays};


    return $namedays->{$country}
        if exists $namedays->{$country};
    
    # Okay, load the nameday info from the sub item
    my $package = "DateTime::Event::NameDay::$country";
    eval "require $package;";
    
    my ($reform_date, $data) = $package->nameday_data();
    my @data = split /\n/, $data;
    undef $data;

    $namedays->{$country} = 
        {reform_date   => $reform_date,
	 names         => {},
	 reverse_names => {},
	 };
    my $forward = $namedays->{$country}{names};
    my $reverse = $namedays->{$country}{reverse_names};
    

    # Format of files:
    # - #s are comments, blank lines are ignored
    # - leading whitespace and trailing whitespace is ignorred
    # - months occur by number on their own line followed by a : (i.e. 1:)
    # - name days are given by number followed by a space then a , separated list of names
    #   surrounding whitespace is trimmed
    # - names starting with * are immovable holidays
    # 
    # e.g.:
    # # Nameday file
    # # Source: www.whatever.com
    #
    # 1: # January
    #   1 *New Year's Day
    #   2 Svea
    #   3 Alfred, Alfrida
    #   ...
    #
    # 2: # February
    #   ...

    my $month = undef;
    foreach my $line (@data) {
	$line =~ s/\s*\#.*//;
	next if $line =~ /^\s*$/;
	
	if ($line =~ /^\s*(\d+)\s+(.*)/) {
	    my ($day, $names) = ($1, $2);

	    # We have a day
	    croak "Malformed nameday file for '$package': Missing month before line '$line'"
		unless defined $month;

	    # Split the names apart and store the forward mapping
	    # For the moment remove the * indicating holidays
	    $names =~ s/\s+$//;
	    my @names = map { s/^*//; $_ } split /\s*,\s*/, $names;
	    $forward->{$month}{$day} = \@names;

	    # Store the reverse mapping
	    foreach my $name (@names) {
		my $n = _clean_name($name);
		croak "Duplicate name '$name' (cleaned '$n')"
		    if exists $reverse->{$n};
		$reverse->{$n} = [$month, $day];
	    }
	}
	elsif ($line =~ /^\s*(\d+):\s*$/) {
	    # Change the month
	    $month = $1;
	}
    }
    @data = ();

    return $namedays->{$country};
}

# Get the canonical sort string for the name... all lowercase
# I would like to make it insensitive to accents too, but there 
# is no good way to do that yet
sub _clean_name {
    my $name = shift;

    $name = lc $name;
#    $name = NFD( lc($name) );
#    $name =~ s/\pM//g;

    return $name;
}

# See if the given country is one we support
sub _check_country {
    my $country = lc shift;
    
    # See if we can load the module
    my $package = "DateTime::Event::NameDay::$country";
    eval "require $package;";

    return $@ ? 0 : 1;
}

1;

__END__

=head1 NAME

DateTime::Event::NameDay - Perl DateTime extension to work with namedays from various countries.

=head1 SYNOPSIS

  use DateTime::Event::NameDay;

  $nd = DateTime::Event::NameDay->new
    (country => "Sweden" , 
     date_args => {reform_date => $ref_dt} );

  @names = $nd->get_daynames( date => $dt);
  # Returns an array of the matching names

  $set = $nd->get_namedays(name => "Alfred");
  # Returns a DateTime::Set object that represents all of the 
  # namedays for Alfred

  # Alternately you can call it without using an object, but
  # now you must specify the country rather than using the
  # one (optionally) passed to the constructor
  @names = DateTime::Event::NameDay->get_daynames
               ( country => "France", date => $dt);
  $set   = DateTime::Event::NameDay->get_namedays
               ( country => "France", name => "Basile");


=head1 DESCRIPTION

DateTime::Event::NameDay is a class that knows the name days for
various countries.  In some countries a person's nameday is more
important than their birthday and gifts may be exchanged.

There are two major functions of the class, the first takes a
C<DateTime> object (of any kind) and works out the names that are
associated with that day.  The second takes a given name and returns a
C<DateTime::Set> object that can be used to work out what dates are
for the given name.

Please note that the calculations are done using the
C<DateTime::Calendar::Christian> module to deal with dates that fall
before the calendar reforms.

=head1 USAGE

TODO

=head1 AUTHOR

Ben Bennett <fiji at limey dot net>

=head1 COPYRIGHT

Copyright (c) 2003 Ben Bennett.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

Portions of the code in this distribution are derived from other
works.  Please see the CREDITS file for more details.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 SEE ALSO

datetime@perl.org mailing list

http://datetime.perl.org/

=cut
