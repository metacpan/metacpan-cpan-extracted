package Date::Calc::Iterator;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.02';

use Date::Calc qw( Delta_Days Add_Delta_Days check_date ) ;
use Ref::Util  qw( is_arrayref is_ref );
use Carp       qw( croak );

use constant FORMAT_ARRAYREF    => 1;
use constant FORMAT_ISO_DASHED  => 2;
use constant FORMAT_ISO_NO_DASH => 3;

use constant DEFAULT_STEP_SIZE  => 1;

sub new {
  my $self  = shift ;
  my %parms = @_ ;

  my $class = ref $self || $self ;

  my ($from, $from_format) = _validate_date_param(\%parms, 'from');
  my ($to,   $to_format)   = _validate_date_param(\%parms, 'to');

  # TODO: should we require that the from format matches the to format?

  if (exists($parms{step}) && $parms{step} !~ /^\d+$/) {
      croak "the 'step' parameter must be an integer";
  }

  my $object          = {
                          from   => $from,
                          to     => $to,
                          format => $from_format,
                          delta  => 0,
                        };

  $object->{step}     = exists($parms{step}) ? $parms{step} : DEFAULT_STEP_SIZE;
  $object->{maxdelta} = Delta_Days(@{$from}, @{$to}) ;

  return bless($object, $class);
}

sub _validate_date_param
{
    my ($params, $key) = @_;
    my $date           = $params->{$key};
    my $ymdref;
    my $format;

    croak "you must provide a '$key' date" unless defined($date);

    if (is_arrayref($date)) {
        $ymdref = $date;
        $format = FORMAT_ARRAYREF;
    }
    elsif (is_ref($date)) {
        croak "unexpected reference type for '$key' parameter";
    }
    # TODO: should probably make these [0-9] instead of \d
    elsif ($date =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/) {
        $ymdref = [$1, $2, $3];
        $format = FORMAT_ISO_DASHED;
    }
    elsif ($date =~ /^(\d\d\d\d)(\d\d)(\d\d)$/) {
        $ymdref = [$1, $2, $3];
        $format = FORMAT_ISO_NO_DASH;
    }
    else {
        croak "unexpected '$key' date '$date'";
    }

    if (check_date(@$ymdref)) {
        return ($ymdref, $format);
    }
    else {
        croak "invalid date for '$key' parameter";
    }

}

sub next {
  my $self = shift ;

  eval { $self->isa('Date::Calc::Iterator') } ;
  die "next() is an object method" if $@ ;

  return undef if $self->{delta} > $self->{maxdelta} ;

  my @next_date = Add_Delta_Days(@{$self->{from}},$self->{delta}) ;
  $self->{delta} += $self->{step} ;
  if ($self->{format} == FORMAT_ARRAYREF) {
      return wantarray ? @next_date : \@next_date ;
  }
  elsif ($self->{format} == FORMAT_ISO_DASHED) {
    return sprintf('%d-%.2d-%.2d', @next_date);
  }
  else {
    return sprintf('%d%.2d%.2d', @next_date);
  }
}

1;

__END__

=head1 NAME

Date::Calc::Iterator - Iterate over a range of dates

=head1 SYNOPSIS

  use Date::Calc::Iterator;

  # This puts all the dates from Dec 1, 2003 to Dec 10, 2003 in @dates1
  my $iterator = Date::Calc::Iterator->new(from => [2003,12,1], to => [2003,12,10]) ;
  while (my $date = $iterator->next) {
      # will produce [2003,12,1], [2003,12,2] ... [2003,12,10]
  }

Or as ISO 8601 format date strings:

  use Date::Calc::Iterator;

  my $iterator = Date::Calc::Iterator->new(from => '2003-12-01', to => '2003-12-10');
  while (my $date = $iterator->next) {
      # will produce '2003-12-01', '2003-12-02' ... '2003-12-10'
  }

=head1 ABSTRACT

Date::Calc::Iterator objects are used to iterate over a range of
dates, day by day or with a specified step.

The B<from> and B<to> dates can either be specified as C<[$year,$month,$day]>
arrayrefs, or as ISO 8601 format date strings (where Christmas Day 2018 is either
C<'2018-12-31'> or C<'20181231'>.

The method next() will return each time a date in the same format that you
specified the B<from> date, or C<undef> when finished.


=head1 WARNING

This module is little and simple. It solves a little problem in a
simple way. It doesn't attempt to be the smarter module on CPAN, nor
the more complete one. If your problem is more complicated than this
module can solve, you should go and check L<DateTime::Event::Recurrence>, which
solves a so broad range of problems that yours can't fall out of it.

Probabily this module won't evolve a lot. Expect bug fixes,
minor improvements in the interface, and nothing more.
If you need to solve bigger problems, you have two choices: vivifying
a 2.x version of the module (after contacting me, of course) or using
DateTime::Event::Recurrence and its brothers.

Anyway, I left the name Iterator, and not Iterator::Day or
DayIterator, for example, so that the module can evolve if the need
be. Who knows? Maybe one day I could need to make it iterate over
weekdays, or over moon phases... let's leave the way open, time will
tell.


=head1 DESCRIPTION

=head2 new

Creates a new object. You B<must> pass it the end points of a date interval
as array references or ISO 8601 date strings.

  $i = Date::Calc::Iterator->new( from => [2003,12,1], to => [2003,12,10] )

C<from> and C<to> are, obviously, required.

Optionally, you can specify a custom step with the C<step> key, for example:

  $i = Date::Calc::Iterator->new(
           from => '2003-12-01',
           to   => '2003-12-31',
           step => 7 );

will iterate over December 2003, week by week, starting from December 1st.


=head2 next

Returns the next date; in list context it returns an array containing
year, month and day in this order, or C<undef> if iteration is over;
in scalar context, it returns a reference to that array, or C<undef>
if iteration is over.



=head1 SEE ALSO

The wonderful L<Date::Calc> module, on top of which this module is made.

L<DateTime::Event::Recurrence> and all the L<DateTime> family from
L<http://datetime.perl.org>. 


=head1 AUTHOR

Marco Marongiu, E<lt>bronto@cpan.orgE<gt>

=head1 THANKS

Thanks to Steffen Beyer, for writing his Date::Calc and for allowing
me to use his namespace.

Thanks to Neil Bowers, who added the support for ISO 8601 format dates,
and the other changes in the 1.01 release.

Blame on me, for being so lazy (or spare-time-missing) that I didn't
make this module compatible with the Date::Calc::Object interface.


=head1 COPYRIGHT AND LICENSE

Copyright 2003-2018 by Marco Marongiu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
