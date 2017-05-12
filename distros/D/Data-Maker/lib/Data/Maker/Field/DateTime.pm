package Data::Maker::Field::DateTime;
use Moose;
use DateTime::Event::Random;
with 'Data::Maker::Field';

our $VERSION = '0.09';

has start => ( is => 'rw');
has end => ( is => 'rw');
has format => ( is => 'rw');
has relative_to => ( is => 'rw');
has subtract => ( is => 'rw', isa => 'HashRef'); 
has add => ( is => 'rw', isa => 'HashRef');

sub generate_value {
  my ($this, $maker) = @_;
  my $dt;
  if ($this->start && $this->end) {
    my $args = {
      start => $this->parse_date_arg('start'),
      end => $this->parse_date_arg('end'),
    };
    $dt = DateTime::Event::Random->datetime(
      %{$args}
    );
  } elsif (my $name = $this->relative_to) {
    my $orig;
    if ($orig = $maker->in_progress($name)) {
    } elsif ( grep(/^$name$/i, qw( now today ) ) ) {
      $orig = DateTime->now;
    }
    if (ref($orig) eq 'DateTime') {
      $dt = $orig->clone;
      my $params;
      if ($params = $this->subtract) {
        my $new_params = check_params($params);
        $dt->subtract_duration( DateTime::Duration->new( %{$new_params} ));
      } elsif ($params = $this->add) {
        my $new_params = check_params($params);
        $dt->add_duration( DateTime::Duration->new( %{$new_params} ));
      }
    }
  }
  if ($this->format) {
    return &{$this->format}($dt);
  }
  return $dt;
}

sub check_params {
  my $params = shift;
	my %params = %{$params};
  for my $key(keys(%params)) {
    my $value = $params{$key};
    if ( my $ref = ref($value) ) {
      if ($ref eq 'ARRAY') {
        $value = Data::Maker->random( $value );
      }	
			$params{$key} = $value;
    }
  }
  return \%params;
}

# `start` and `end` can be either a year or an actual DateTime object.  This method determines which it is and 
sub parse_date_arg {
  my ($this, $keyword) = @_;
  if (my $in = $this->$keyword) {
    if (ref($in) && $in->isa('DateTime')) {
      return $in;
    } elsif ($in =~ /^\d{4}$/) {
      return DateTime->new( year => $in );
    } else {
      die "Invalid `$keyword` argument to " . __PACKAGE__;
    }
  }
}
1;

__END__

=head1 NAME 

Data::Maker::Field::DateTime - A L<Data::Maker> field class that generates L<DateTime> values.

=head1 SYNOPSIS 

  use Data::Maker;
  use Data::Maker::Field::DateTime;

  my $maker = Data::Maker->new(
    record_count => 10,
    fields => [
      {
        name => 'date_of_birth',
        class => 'Data::Maker::Field::DateTime',
        args => {
          relative_to => 'now',
          subtract => { years => [0..80], days => [0..365] ]
        }
      }
    ]
  );

=head1 DESCRIPTION 

Data::Maker::Field::DateTime takes any of the following arguments:

=over 4

=item * B<start>

By default, DateTime could return ANY date and time.  This is usually not what you want. This parameter can be either a L<DateTime> object, or a four-digit year.  The DateTime object returned will be no earlier than given date, or January 1st of given year.

=item * B<end>

This is the other end of the range that begins with C<start()> (above).  The DateTime object returned will be no later than the given date, or January 1st of the given year. 

=item * B<format> (I<CodeRef>)

A code reference that will be passed the generated DateTime object immediately before the random value is returned to Data::Maker.  While it is often most useful to return the DateTime object itself, it is occasionally preferred to return a string representation of the date so your other code doesn't have to deal with DateTime objects.  This is how you would do this.

=item * B<relative_to>

The name of another L<Data::Maker::Field::DateTime> field in the same L<Data::Maker> object.  Combined with the C<subtract()> or C<add()> parameters (below), this allows you to generate a random L<Data::Maker::Field::DateTime> object that is relative to an already-generated L<Data::Maker::Field::DateTime> object in the same record.  Note that you can only use this parameter to refer to a field that appears previous to this field in the list.

In addition to specifying the name of another field, you can also use the keyword 'now' or the keyword 'today', both of which have the same effect:  DateTime->now is used as the starting point.   This is useful for many things.  The example at the beginning of this POD demonstrates how to use this feature to generate a birthday of somebody between 20 and 80 years old.

=item * B<subtract> (I<HashRef>)

This parameter takes a hash reference that is passed to L<DateTime::Duration> as the amount of time to subtract from the L<Data::Maker::Field::DateTime> object referrred to by the C<relative_to()> parameter (see above).

It can either be a fixed value...

  subtract => { months => 2 }

...or it can be a randomly-chosen value, by simply passing an array reference of choices or a range:

  subtract => { years => [0..80], days => [0..365] ]

=item * B<add> (I<HashRef>)

This parameter is just like C<subtract()> (above), but it moves the L<Data::Maker::Field::DateTime> object in the opposite direction.

=back

=head1 AUTHOR

John Ingram (john@funnycow.com)

=head1 LICENSE

Copyright 2013 by John Ingram. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
