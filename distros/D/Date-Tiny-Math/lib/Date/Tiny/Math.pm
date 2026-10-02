package Date::Tiny::Math;

use 5.006;
use strict;
use warnings;

use parent 'Date::Tiny';

use Carp;
use POSIX qw(floor);
use Scalar::Util qw(looks_like_number);

use overload
  '+' => \&plus,
  '-' => \&minus,
  '<=>' => \&numcmp,
;

our $VERSION = '1.00';

=encoding utf8

=head1 NAME

Date::Tiny::Math - A date object with maths, with as little code as
possible

=head1 SYNOPSIS

    use Date::Tiny::Math;

    # How many days have elapsed since 1 January 2000?
    $date = Date::Tiny::Math->new(year => 2000, month => 1, day => 1);
    $date2 = Date::Tiny::Math->new; # today
    $elapsed_days = $date2 - $date;

    $date3 = $date2 + 100;      # 100 days after today
    $date2 -= 7;                # shift back by 7 days
    ++$date2;                   # increment by 1 day

    print "earlier\n" if $date2 < $date3;

=head1 DESCRIPTION

Date::Tiny::Math is a subclass of L<Date::Tiny> and adds the ability
to do simple arithmetic with the dates, assuming those dates to be
specified in the common, Gregorian, calendar -- even for dates
preceding the introduction of the Gregorian calendar in the year 1582.

=head1 METHODS

The below list of methods is in addition to the methods provided by
L<Date::Tiny>.

=cut

=head2 new

  $date = Date::Tiny::Math->new(year => 2000, month => 1, day => 1);
  $date = Date::Tiny::Math->new(cjdn => 2451545);

Creates a new instance based on the specified calendar date (year,
month, day) or Chronological Julian Day Number (CJDN).  The CJDN is a
count of days since 24 November −4713 (Gregorian).  It can be
positive, zero, or negative.

The Chronological Julian Day Number is distinct from the better known
integer Julian Day Number (JDN) and fractional Julian Day (JD) in that
the days don't begin at noon UTC but correspond to calendar days at
the location of interest.

=cut

sub new {
  my ($class, %options) = @_;
  my $self;
  if (exists $options{cjdn}) {
    croak "Cannot specify both a calendar date and the CJDN"
      if exists $options{year}
      or exists $options{month}
      or exists $options{day};
    $self = bless Date::Tiny->new, $class;
    return $self->_set_cjdn($options{cjdn});
  } else {
    return bless Date::Tiny->new(%options), $class;
  }
}

=head2 cjdn

  $cjdn = $date->cjdn;  # returns 2451545 for 2000-01-01

Returns the Chronological Julian Day Number (CJDN) for the specified
date object.  The CJDN is the integer day count since 24 November
−4713 (Gregorian).  It can be positive, zero, or negative.

=cut

sub cjdn {
  my ($self) = @_;
  unless (exists $self->{cjdn}) {
    # based on https://aa.quae.nl/en/reken/juliaansedag.html
    my ($alpha1, $m1) = idiv($self->{month} - 3, 12);
    my $a1 = $self->{year} + $alpha1;
    my ($c1, $a2) = idiv($a1, 100);
    my $d1 = idiv(153*$m1 - 3, 5) + $self->{day};
    my $d2 = idiv(36525*$a2, 100) + $d1;
    $self->{cjdn} = idiv(146097*$c1, 4) + $d2 + 1721120;
  }
  return $self->{cjdn};
}

=head2 +, ++, +=

  $date2 = $date1 + 17;         # get the date 17 days later
  $date2 = 17 + $date1;         # same as previous
  $date1 += 17;                 # modifies $date1
  ++$date1;                     # adds 1 day to $date1

Adds a number to a date.  The number is rounded down to the nearest
integer if needed.

Croaks if the non-date argument is not numerical.

=cut

sub plus {
  my ($self, $other, $swap) = @_;
  croak 'Cannot add a ' . ref($other) . " to a Date::Tiny::Math\n"
    if ref $other;
  croak "Cannot add a non-numerical scalar to a Date::Tiny::Math\n"
    unless looks_like_number($other);
  # create a clone of $self
  my $result = bless { %{$self} }, ref($self);
  $result->_set_cjdn($self->cjdn + $other);
  return $result;
}

=head2 -, --, -+

  $date2 = $date1 - 17;         # get the date 17 days earlier
  $date1 -= 17;                 # modifies $date1
  $offset_in_days = $date2 - $date1; # difference between two dates
  --$date1;                     # subtracts 1 day from $date1

  # these croak:

  $date2 = 17 - $date1;         # cannot subtract a date from a number
  $date2 -= $date1;             # cannot modify LHS from date to scalar

Subtracts a number or a date from a date.  The number is rounded down
to the nearest integer as needed.

If both arguments are dates then their difference measured in days is
returned.

Croaks if the non-date argument is not numerical, or if the left-hand
side isn't a L<Date::Tiny::Math>.

=cut

sub minus {
  my ($self, $other, $swap) = @_;
  # $self is always a Date::Tiny::Math;
  if (ref $other) {
    if ($other->isa('Date::Tiny')) { # want difference in days
      # $other may not be a Date::Tiny::Math
      $other = bless { %{$other} }, ref($self)
        unless $other->isa('Date::Tiny::Math');
      my $d = $other->cjdn - $self->cjdn;
      return $swap? $d: -$d;
    }
    croak 'Cannot subtract a ' . ref($other) . " from a Date::Tiny::Math\n"
      if $swap;
    croak 'Cannot subtract a Date::Tiny::Math from a ' . ref($other) . "\n";
  }
  croak "Cannot subtract a Date::Tiny::Math from a non-Date::Tiny::Math\n"
    if $swap;
  croak "Cannot subtract a non-numerical scalar from a Date::Tiny::Math\n"
    unless looks_like_number($other);
  # otherwise want shifted date
  # create a clone of $self
  my $result = bless { %{$self} }, ref($self);
  $result->_set_cjdn($self->cjdn - $other);
  return $result;
}

=head2 numerical comparison

  $date2 == $date3;             # also < <= != <=> => >

Instances of L<Date::Tiny::Math> have the same order as their CJDN
values.  Later dates compare as greater than earlier dates.

Croaks if not both arguments are instances of L<Date::Tiny::Math>.

NOTE: L<Date::Tiny>, the parent of the current module, does not
provide numerical comparison.  It provides stringwise equality (C<eq>)
and not-equality (C<ne>) operators instead, which compare the
stringified versions of the dates.  The current module inherits those
stringwise operators.  It does not expand stringwise comparison by
implementing the inequality operators (C<lt>, C<le>, C<ge>, C<gt>)
because stringwise comparison does not define the same order as
numerical comparison when negative year numbers are involved.

=cut

sub numcmp {
  my ($self, $other, $swap) = @_;
  croak "Cannot compare a Date::Tiny::Math to a non-Date::Tiny::Math\n"
    unless ref($other) and $other->isa('Date::Tiny::Math');
  my $d = $other->cjdn - $self->cjdn;
  return $swap? $d: -$d;
}

# internal methods and subroutines, not exposed:

# Integer division of $n by $d.  Calculates $q and $r such that $n =
# $q*$d + $r and 0 < $r ≤ abs($d).  Returns ($q, $r) in list context,
# or $q in scalar context.
sub idiv {
  my ($n, $d) = @_;
  use integer;
  return undef unless $d;       # prevent division by zero
  my $q = $n/$d;
  # rounding is likely toward zero, which means the remainder may be
  # negative but we want it to always be nonnegative
  my $r = $n%$d;
  if ($r < 0) {
    --$q;
    $r += abs($d);
  }
  return wantarray? ($q, $r): $q;
}

# Sets the date object according to a CJDN.  $cjdn is rounded down to
# the nearest integer.  Returns the object.
sub _set_cjdn {
  my ($self, $cjdn) = @_;
  $cjdn = floor($cjdn);
  if (not(defined $self->{cjdn}) or $self->{cjdn} != $cjdn) {
    use integer;
    $self->{cjdn} = $cjdn;
    my $s = $cjdn - 1721120;
    my ($c1, $omega3) = idiv(4*$s + 3, 146097);
    my $d2 = idiv($omega3, 4);
    my ($a2, $omega4) = idiv(100*$d2 + 99, 36525);
    my $d1 = idiv($omega4, 100);
    my ($m1, $omega5) = idiv(5*$d1 + 2, 153);
    my $d0 = idiv($omega5, 5);
    my ($alpha1, $m0) = idiv($m1 + 2, 12);
    my $a1 = 100*$c1 + $a2;
    $self->{year} = $a1 + $alpha1;
    $self->{month} = $m0 + 1;
    $self->{day} = $d0 + 1;
  }
  $self;
}

=head1 AUTHOR

Louis Strous, C<< <lstrous at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-date-tiny-math at
rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Tiny-Math>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Tiny::Math

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Tiny-Math>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Date-Tiny-Math>

=item * Search CPAN

L<https://metacpan.org/release/Date-Tiny-Math>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Louis Strous.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Date::Tiny::Math
