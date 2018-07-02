use 5.008;
use strict;
use warnings;

{
	package DateTimeX::Auto;
	
	use overload ();
	use Carp qw( croak );
	use Exporter::Shiny 0.036 qw( d dt dur );
	
	BEGIN {
		$DateTimeX::Auto::AUTHORITY = 'cpan:TOBYINK';
		$DateTimeX::Auto::VERSION   = '0.009';
	}
	
	our %EXPORT_TAGS = (
		auto => sub {
			my $class = shift;
			my ($name, $args, $globals) = @_;
			
			my $datetime_class = $args->{datetime_class} || "$class\::DateTime";
			my $duration_class = $args->{duration_class} || "$class\::Duration";
			
			overload::constant "q" => sub {
				return $_[1] unless $_[2] eq "q";
				$datetime_class->new($_[0]) or $duration_class->new($_[0]) or $_[1];
			};
			
			return;
		},
	);
	
	sub unimport
	{
		overload::remove_constant "q" => undef;
	}
	
	sub _generate_d
	{
		my $class = shift;
		my ($name, $args, $globals) = @_;
		my $datetime_class = $args->{datetime_class} || "$class\::DateTime";
		
		sub {
			return $datetime_class->now if not @_;
			$datetime_class->new("$_[0]")
				or croak("Could not turn '$_[0]' into a DateTime; stopped");
		};
	}
	
	sub _generate_dt
	{
		shift->_generate_d(@_);
	}
	
	sub _generate_dur
	{
		my $class = shift;
		my ($name, $args, $globals) = @_;
		my $duration_class = $args->{duration_class} || "$class\::Duration";
		
		sub {
			$duration_class->new("$_[0]")
				or croak("Could not turn '$_[0]' into a Duration; stopped");
		};
	}
	
	# For back-compat, allow construtor to be called for this package
	sub new
	{
		shift;
		'DateTimeX::Auto::DateTime'->new(@_);
	}
}

{
	package DateTimeX::Auto::DateTime;
	
	use parent qw[DateTime];
	BEGIN { eval 'use UNIVERSAL::ref;' };
	use constant ref => 'DateTime';
	
	use DateTime::Format::Strptime qw[];
	
	BEGIN {
		$DateTimeX::Auto::DateTime::AUTHORITY = 'cpan:TOBYINK';
		$DateTimeX::Auto::DateTime::VERSION   = '0.009';
	}
	
	sub from_object
	{
		my ($proto, %args) = @_;
		
		my %x;
		my $rv = $proto->SUPER::from_object(%args);
		$rv->{+__PACKAGE__} = { %x } if %x = %{ $args{object}->{+__PACKAGE__} };
		
		return $rv;
	}
	
	sub new
	{
		if (scalar @_ > 2)
		{
			my $class = shift;
			return $class->SUPER::new(@_);
		}
		
		my ($class, $string) = @_;
		
		if ($string =~ /^(\d{4})-(0[1-9]|1[0-2])-([0-2][0-9]|30|31)(Z?)$/)
		{
			my $dt;
			my $z = defined($4) ? $4 : '';
			eval {
				$dt = $class->SUPER::new( year => $1, month=>$2, day=>$3, hour=>0, minute=>0, second=>0 );
				$dt->{+__PACKAGE__}{format} = 'D';
				if ($z eq 'Z' and defined $dt)
				{
					$dt->set_time_zone('UTC');
					$dt->{+__PACKAGE__}{trailer} = $z;
				}
			};
			return $dt if $dt;
		}
		
		if ($string =~ /^(\d{4})-(0[1-9]|1[0-2])-([0-2][0-9]|30|31)T([0-1][0-9]|2[0-4]):([0-5][0-9]):([0-5][0-9]|60)(\.[0-9]+)?(Z?)$/)
		{
			my $dt;
			my $z    = defined($8) ? $8 : '';
			my $nano = defined($7) ? $7 : '';
			eval {
				$dt = $class->SUPER::new( year => $1, month=>$2, day=>$3, hour=>$4, minute=>$5, second=>$6 );
				$dt->{+__PACKAGE__}{format} = 'DT';
				if (length $nano and defined $dt)
				{
					$dt->{+__PACKAGE__}{format} = length($nano) - 1;
					$dt->{rd_nanosecs} = substr($nano.('0' x 9), 1, 9) + 0;
				}
				if ($z eq 'Z' and defined $dt)
				{
					$dt->set_time_zone('UTC');
					$dt->{+__PACKAGE__}{trailer} = $z;
				}
			};
			return $dt if $dt;
		}
		
		return undef;
	}
	
	sub set_time_zone
	{
		my ($self, @args) = @_;
		delete $self->{+__PACKAGE__}{trailer};
		$self->SUPER::set_time_zone(@args);
	}
	
	use overload '""' => sub
	{
		my ($self) = @_;
		
		return $self->SUPER::_stringify
			unless exists $self->{+__PACKAGE__};
		
		my $trailer = $self->{+__PACKAGE__}{trailer};
		$trailer = '' unless defined $trailer;
		
		return $self->ymd('-') . $trailer
			if $self->{+__PACKAGE__}{format} eq 'D';
		
		return sprintf('%sT%s%s', $self->ymd('-'), $self->hms(':'), $trailer)
			if $self->{+__PACKAGE__}{format} eq 'DT';
		
		my $nano = substr(
			$self->strftime('%N') . ('0' x $self->{+__PACKAGE__}{format}),
			0,
			$self->{+__PACKAGE__}{format},
		);
		sprintf(
			'%sT%s.%s%s',
			$self->ymd('-'),
			$self->hms(':'),
			$nano,
			$trailer,
		);
	};
}

{
	package DateTimeX::Auto::Duration;
	
	use parent qw[DateTime::Duration];
	BEGIN { eval 'use UNIVERSAL::ref;' };
	use constant ref => 'DateTime::Duration';
	
	BEGIN {
		$DateTimeX::Auto::Duration::AUTHORITY = 'cpan:TOBYINK';
		$DateTimeX::Auto::Duration::VERSION   = '0.009';
	}
	
	sub new
	{
		if (scalar @_ > 2)
		{
			my $class = shift;
			return $class->SUPER::new(@_);
		}
		
		my ($class, $string) = @_;
		
		return undef unless $string =~ /^
			([\+\-])?          # Potentially negitive...
			P                  # Period of...
			(?:([\d\.]*)Y)?    # n Years
			(?:([\d\.]*)M)?    # n Months
			(?:([\d\.]*)W)?    # n Weeks
			(?:([\d\.]*)D)?    # n Days
			(?:
				T               # And a time of...
				(?:([\d\.]*)H)? # n Hours
				(?:([\d\.]*)M)? # n Minutes
				(?:([\d\.]*)S)? # n Seconds
			)?
		/ix;
			
		my $X = {
			I   => $1,
			y   => $2,
			m   => $3,
			w   => $4,
			d   => $5,
			h   => $6,
			min => $7,
			s   => $8,
			n   => 0,
		};
		
		# Handle fractional
		foreach my $frac (qw(y=12.m m=30.d w=7.d d=24.h h=60.min min=60.s s=1000000000.n))
		{
			my ($big, $mult, $small) = split /[\=\.]/, $frac;
			next unless $X->{$big} =~ /\./;
			
			my $int_part  = int($X->{$big});
			my $frac_part = $X->{$big} - $int_part;
			
			$X->{$big}    =  $int_part;
			$X->{$small} += ($mult * $frac_part);
		}
		$X->{'n'} = int($X->{'n'});
		
		# Construct and return object.
		my $dur = $class->SUPER::new(
			years       => $X->{'y'}   || 0,
			months      => $X->{'m'}   || 0,
			weeks       => $X->{'w'}   || 0,
			days        => $X->{'d'}   || 0,
			hours       => $X->{'h'}   || 0,
			minutes     => $X->{'min'} || 0,
			seconds     => $X->{'s'}   || 0,
			nanoseconds => $X->{'n'}   || 0,
		);
		
		$X->{'I'} eq '-' ? $dur->inverse : $dur;
	}
	
	use overload '""' => sub
	{
		my $self = shift;
		
		# We coerce weeks into days and nanoseconds into fractions of a second
		# for compatibility with xsd:duration.
		my $_days = $self->days + (7 * $self->weeks);
		my $_secs = $self->seconds + ($self->nanoseconds / 1000000000);
		
		my $str = $self->is_negative ? '-P' : 'P';
		$str .= $self->years   . 'Y' if $self->years;
		$str .= $self->months  . 'M' if $self->months;
		$str .= $_days         . 'D' if $_days;
		$str .= 'T';
		$str .= $self->hours   . 'H' if $self->hours;
		$str .= $self->minutes . 'M' if $self->minutes;
		$str .= $_secs         . 'S' if $_secs;
		
		$str =~ s/T$//;
		
		return $str;
	};
}

__FILE__
__END__

=head1 NAME

DateTimeX::Auto - use DateTime without needing to call constructors

=head1 SYNOPSIS

 use DateTimeX::Auto -auto;
 
 my $ga_start = '2000-04-06' + 'P10Y';
 printf("%s %s\n", $ga_start, ref $ga_start);  # 2010-04-06 DateTime
 
 {
   no DateTimeX::Auto;
   my $string = '2000-04-06';
   printf( "%s\n", ref($string) ? 'Ref' : 'NoRef' );  # NoRef
 }

=head1 DESCRIPTION

L<DateTime> is awesome, but constructing C<DateTime> objects can be
annoying. You often need to use one of the formatter modules, or call
C<< DateTime->new() >> with a bunch of values. If you've got a bunch of
constant dates in your code, then C<DateTimeX::Auto> makes all this a bit
simpler.

It uses L<overload> to overload the C<< q() >> operator, automatically
turning all string constants that match particular regular expressions
into C<DateTime> objects. It also overloads stringification to make sure
that C<DateTime> objects get stringified back to exactly the format they
were given in.

The date formats supported are:

 yyyy-mm-dd
 yyyy-mm-ddZ
 yyyy-mm-ddThh:mm:ss
 yyyy-mm-ddThh:mm:ssZ

The optional trailing 'Z' puts the datetime into the UTC timezone. Otherwise
the datetime will be in DateTime's default (floating) timezone.

Fractional seconds are also supported, to an arbitrary number of decimal
places. However, as C<DateTime> only supports nanosecond precision, any
digits after the ninth will be zeroed out.

 my $dt         ='1234-12-12T12:34:56.123456789123456789';
 print "$dt\n"; # 1234-12-12T12:34:56.123456789000000000

Objects are blessed into the C<DateTimeX::Auto::DateTime> class which
inherits from C<DateTime>. They use L<UNIVERSAL::ref> (if installed) to
masquerade as plain C<DateTime> objects.

 print ref('2000-01-01')."\n";   # DateTime

Additionally, ISO 8601 durations are supported:

  my $dt = '2000-01-01';
  say( $dt + 'P4Y2M12D' );  # 2004-03-13

Durations are possibly not quite as clever at preserving the incoming
string formatting.

=head2 The C<< d >> and C<< dt >> Functions

As an alternative C<DateTimeX::Auto> can export a function called C<d>.
This might be useful if you'd prefer not to have every string constant in
your code turned into a C<DateTime>.

 use DateTimeX::Auto 'd';
 my $dt = d('2000-01-01');

If C<d> is called with a string that is in an unrecognised format, it
croaks. If called with no arguments, returns a C<DateTime> representing
the current time.

An alias C<dt> is also available. They're exactly the same.

=head2 The C<< dur >> Function

Called with an ISO 8601 duration string, returns a
L<DateTimeX::Auto::Duration> object.

=head2 Object-Oriented Interface

This somewhat negates the purpose of the module, but it's also possible
to use it without exporting anything, in the usual normal Perl object-oriented
fashion:

 use DateTimeX::Auto;
 
 my $dt1 = DateTimeX::Auto::DateTime->new('2000-01-01T12:00:00.1234');
 
 # Traditional DateTime style
 my $dt2 = DateTimeX::Auto::DateTime->new(
   year  => 2000,
   month => 2,
   day   => 3,
 );

Called in the traditional DateTime style, throws an exception if the date
isn't valid. Called in the DateTimeX::Auto::DateTime stringy style, returns
undef if the date isn't in a recognised format, but throws if it's otherwise
invalid (e.g. 30th of February).

There is similarly a DateTimeX::Auto::Duration class which is a similar
thin wrapper around DateTime::Duration.

=head1 EXAMPLES

 use DateTimeX::Auto ':auto';
 
 my $date = '2000-01-01';
 while ($date < '2000-02-01')
 {
   print "$date\n";
   $date += 'P1D'; # add one day
 }

 use DateTimeX::Auto 'd';
 
 my $date = d('2000-01-01');
 while ($date < d('2000-02-01'))
 {
   print "$date\n";
   $date += dur('P1D'); # add one day
 }

=head1 SEE ALSO

L<DateTime>, L<DateTime::Duration>, L<DateTimeX::Easy>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011-2012, 2014 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
