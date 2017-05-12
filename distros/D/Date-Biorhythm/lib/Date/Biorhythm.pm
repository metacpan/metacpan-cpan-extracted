package Date::Biorhythm;

use strict;
use warnings;

use Moose;
use Date::Calc::Object qw(:all);
use Math::Trig;

our $VERSION = '2.2';

our $WAVELENGTH = {
  emotional    => 28,
  intellectual => 33,
  physical     => 23,
};

our $SECONDARY_CYCLES = {
  mastery => 1,
  passion => 1,
  wisdom  => 1,
};

has 'name' => (
  is  => 'rw',
);

has 'birthday' => (
  isa => 'Date::Calc::Object',
  is  => 'rw',
);

has 'day' => (
  isa => 'Date::Calc::Object',
  is  => 'rw',
);

has '__cache' => (
  is  => 'ro',
);

# initializer for constructor
sub BUILD {
  my $self   = shift;
  my $params = shift;

  die "birtday => REQUIRED!" if not defined $params->{birthday};

  $self->{__cache} = {
    emotional    => [],
    intellectual => [],
    physical     => [],
  };
}

# finalizer for destructor
sub DEMOLISH { }

# what day in the cycle are we in?
sub index {
  my ($self, $cycle) = @_;
  my $diff  = $self->day - $self->birthday;
  my $days  = abs($diff);
  return $days % $WAVELENGTH->{$cycle};
}

# return the current amplitude of the cycle as a value between -1 and 1
sub value {
  my ($self, $cycle) = @_;
  my $day   = $self->index($cycle);
  if (exists($SECONDARY_CYCLES->{$cycle})) {
    if ($cycle eq 'mastery') {
      return ($self->value('intellectual') + $self->value('physical'))     / 2;
    } elsif ($cycle eq 'passion') {
      return ($self->value('physical')     + $self->value('emotional'))    / 2;
    } elsif ($cycle eq 'wisdom') {
      return ($self->value('emotional')    + $self->value('intellectual')) / 2;
    }
  } else {
    if (exists($self->{__cache}{$cycle}[$day])) {
      return $self->{__cache}{$cycle}[$day];
    } else {
      return $self->{__cache}{$cycle}[$day] = 
        sin(pi * 2 * ($day / $WAVELENGTH->{$cycle}));
    }
  }
}

# go to the next day
sub next {
  my ($self) = @_;
  $self->{day}++;
}

# go to the previous day
sub prev {
  my ($self) = @_;
  $self->{day}--;
}

1;

__END__

=head1 NAME

Date::Biorhythm - a biorhythm calculator

=head1 SYNOPSIS

From the command line

  biorhythm --birthday=1994-10-09

Usage

  use Date::Biorhythm;
  my $bio = Date::Biorhythm->new({
    birthday => Date::Calc::Object->new(0, 1970, 1, 1),
    name     => 'Unix',
  });

  my $i = 0;
  my $limit = 365;
  $bio->day(Date::Calc::Object->today);
  while ($i < $limit) {
    print $bio->value('emotional'), "\n";
    $bio->next;
    $i++;
  }

=head1 DESCRIPTION

I find biorhythms mildly amusing, but I got tired of visiting
http://www.facade.com/biorhythm and having to deal with their
web-based form for date entry.

I vaguely remembered there being a Perl module for biorhythm
calculation, but I couldn't find it on CPAN.  However, further
investigation finally led me to BackPAN where I found Date::Biorhythm
1.1 which was written by Terrence Brannon (a long time ago).

Wanting an excuse to try L<Moose|Moose> out, I decided to make a
new and modernized version of Date::Biorhythm, and this is the
result.

=head1 BUT WTF IS A BIORHYTHM?

!http://i41.photobucket.com/albums/e271/sr5i/GoogleMotherFucker.jpg!

http://en.wikipedia.org/wiki/Biorhythm

=head1 METHODS

=head2 meta

This method was added by Moose, and it gives you access to Date::Biorhythm's
metaclass.  (See L<Moose|Moose> for more details.)

=head2 new

The constructor.  It takes on optional hashref that will accept the following keys:
name, birthday, and day.

=head2 name

Get or set the name associated with this biorhythm.  This will usually
be a person's name.

=head2 birthday

Get or set the birthday used for this biorhythm.

=head2 day

Get or set the current day (which is represented by a Date::Calc::Object).

=head2 next

Go forward one day by incrementing $self->day.

=head2 prev

Go backward one day by decrementing $self->day.

=head2 index

Given a primary cycle (such as 'emotional', 'intellectual', or 'physical'),
return how many days we are into the cycle.  Note that the first day of the
cycle returns 0.

=head2 value

Given a primary cycle or secondary cycle, return a value between -1 and 1
that represents the current amplitude in the cycle.

=head1 SEE ALSO

http://www.facade.com/biorhythm

=head1 AUTHOR

Terrence Brannon E<lt>metaperl@gmail.comE<gt>

John Beppu E<lt>beppu@cpan.orgE<gt>

=cut
