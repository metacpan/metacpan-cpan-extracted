package DateTimeX::Duration::SkipDays;

# # no critic qw( Modules::RequireExplicitInclusion )

# ABSTRACT: Given a starting date, a number of days and a list of days to be skipped, returns the date X number of days away.

use 5.006;
use strict;
use warnings;

use Carp;
use DateTime;
use DateTime::Event::Holiday::US;
use DateTime::Format::Flexible;
use Try::Tiny;
use List::MoreUtils 'any';

# The circular::require test is having problems with one or more of the above modules, so we'll skip it.

## efm skip circular

our $VERSION = '0.002'; # VERSION


sub new {

  my ( $class, $arg ) = @_;

  croak 'Must pass nothing or a reference to a hash to new'
    if ref $arg && ref $arg ne 'HASH';

  my $self = bless {}, $class;

  $self->{ 'bad_format' }   = {};
  $self->{ 'days_to_skip' } = DateTime::Set->empty_set;

  for my $key ( keys %$arg ) { ## no critic qw( References::ProhibitDoubleSigils )

    next if $key eq 'add';

    if ( my $method = $self->can( $key ) ) {

      ## no critic qw( ValuesAndExpressions::ProhibitAccessOfPrivateData )
      $self->$method( $arg->{ $key } );

    }
  }

  return $self;

} ## end sub new


sub start_date {

  my ( $self, $start_date ) = @_;

  croak 'Must pass a DateTime object to start'
    if ref $start_date ne 'DateTime';

  $self->{ 'start_date' } = $start_date->clone->truncate( 'to' => 'day' );

  return 1;

}


sub days_to_skip {

  my ( $self, @days_to_skip ) = @_;

  $self->{ 'days_to_skip' } = $self->{ 'days_to_skip' }->union( $_ ) for @days_to_skip;

  return 1;

}


sub parse_dates {

  my ( $self, $skip_dates ) = @_;

  croak 'Expected scalar'
    if ref $skip_dates;

  my @known_holidays = DateTime::Event::Holiday::US::known();

  for my $line ( split /\n/, $skip_dates ) {

    next if $line =~ /^\s*$/;
    $line =~ s/^\s*(\S.*?)\s*$/$1/;
    $line =~ s/\s+/ /g;

    my $dt;

    if ( $line =~ /^RRULE:/i ) {

      $dt = DateTime::Format::ICal->parse_recurrence( 'recurrence' => $line );

      ## no tidy
    } elsif ( any { /$line/ } @known_holidays ) {
      ## use tidy

      $dt = DateTime::Event::Holiday::US::holiday( $line );

    } else {

      ## no critic qw( TestingAndDebugging::ProhibitNoWarnings ErrorHandling::RequireCheckingReturnValueOfEval )
      eval { no warnings 'uninitialized'; $dt = DateTime::Format::Flexible->parse_datetime( $line ) };
      ## use critic

      if ( $@ ) {

        ( my $err = $@ ) =~ s/^(Invalid date format: $line).*$/$1/ms;

        $self->{ 'bad_format' }{ $line } = $err;
        next;

      }

      # This fails with
      # Can't call method "can" on an undefined value at /usr/local/share/perl/5.10.1/DateTime/Set.pm line 593.
      # and I don't have time to figure out what's wrong. So, the above is going to have to do.
      #
      #try {
      #
      #  $dt = DateTime::Format::Flexible->parse_datetime( $line );
      #
      #} catch {
      #
      #  ( my $err = $_ ) =~ s/^(Invalid date format: $line).*$/$1/ms;
      #
      #  $self->{ 'bad_format' }{ $line } = $err;
      #
      #}
    } ## end else [ if ( $line =~ /^RRULE:/i)]

    $self->days_to_skip( $dt );

  } ## end for my $line ( split...)

  return 1;

} ## end sub parse_dates


sub bad_format { ## no critic qw( Subroutines::RequireArgUnpacking )
  return wantarray ? keys %{ $_[0]->{ 'bad_format' } } : $_[0]->{ 'bad_format' };
}


sub add {

  my ( $self, $x ) = @_;

  { no warnings 'numeric'; $x += 0 } ## no critic qw( TestingAndDebugging::ProhibitNoWarnings )

  croak 'Must provide integer larger than or equal to 0'
    if $x < 0;

  # XXX: Need better error handling here
  croak 'No start date provided'
    unless exists $self->{ 'start_date' };

  # XXX: Need better error handling here
  croak 'No days_to_skip provided'
    unless exists $self->{ 'days_to_skip' };

  my $duration = DateTime::Duration->new( 'days' => $x );
  my $span = DateTime::Span->from_datetime_and_duration( 'start' => $self->{ 'start_date' }, 'duration' => $duration );
  my $skipped = $span->intersection( $self->{ 'days_to_skip' } );

  my $count = my $new_count = 0;

  my $iter = $skipped->iterator;
  $count++ while $iter->next;

  while ( $count != $new_count ) {

    $duration = DateTime::Duration->new( 'days' => $x + $count );
    $span = DateTime::Span->from_datetime_and_duration( 'start' => $self->{ 'start_date' }, 'duration' => $duration );
    $skipped = $span->intersection( $self->{ 'days_to_skip' } );

    $iter = $skipped->iterator;
    my $new_count; $new_count++ while $iter->next;

    last if $new_count == $count;
    $count = $new_count;

  }

  ## no critic qw( ValuesAndExpressions::ProhibitCommaSeparatedStatements )
  return wantarray ? ( $span, $skipped ) : { 'span' => $span, 'skipped' => $skipped };

} ## end sub add


1;

__END__
=pod

=head1 NAME

DateTimeX::Duration::SkipDays - Given a starting date, a number of days and a list of days to be skipped, returns the date X number of days away.

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 #!/usr/bin/perl

 use strict;
 use warnings;

 use DateTime;
 use DateTimeX::Duration::SkipDays;

 my $skip_days = q(

 Christmas
 Christmas Eve
 RRULE:FREQ=WEEKLY;BYDAY=SA,SU

 );

 my $skip_x_days = 30;
 my $start_date  = DateTime->new( 'year' => 2011, 'month' => 12, 'day' => 1 );

 my $s = DateTimeX::Duration::SkipDays->new({
   'parse_dates'  => $skip_days,
   'start_date'   => $start_date,
 });

 my ( $span, $skipped ) = $s->add( $skip_x_days );

 printf "\nCalculated Start: %s\nCalculated End:  %s\n", $span->start->ymd, $span->end->ymd;

 my $iter = $skipped->iterator;

 while ( my $dt = $iter->next ) {

   printf "\nSkipped: %s", $dt->min->ymd;

 }

 if ( @{ $s->bad_format } ) {

   print "\n\nUnrecognized formats:";
   print "\n\t$_" for @{ $s->bad_format };

 }

 # should output

 # Calculated Start: 2011-12-01
 # Calculated End:  2012-01-12

 # Skipped: 2011-12-03
 # Skipped: 2011-12-04
 # Skipped: 2011-12-10
 # Skipped: 2011-12-11
 # Skipped: 2011-12-17
 # Skipped: 2011-12-18
 # Skipped: 2011-12-24
 # Skipped: 2011-12-25
 # Skipped: 2011-12-31
 # Skipped: 2012-01-01
 # Skipped: 2012-01-07
 # Skipped: 2012-01-08

=head1 METHODS

=head2 new( [\%HASH] )

With no arguments an empty object is returned.

This method will croak if a non-hash reference is passed to it.

The possible keys for the constructor are any of the available methods below,
except for C<add>.  The C<add> method must be called explicitly. Unknown keys
will be silently ignored.

The values have the same requirement as the matching methods.

Returns a C<DateTimeX::Duration::SkipDays> object.

=head2 start_date( DateTime )

C<start_date> is expecting a L<DateTime> object. This will be used as the
starting point for calculations.

Returns true on success.

=head2 days_to_skip

C<days_to_skip> accepts any object, or array of objects that will be added to the
current list of days to be skipped.

Currently, L<DateTime>, L<DateTime::Span>, L<DateTime::Set>,
L<DateTime::Set::ICal> and L<DateTime::SpanSet> are known to work.  Anything
that can be used with L<DateTime::Set>'s union method should work.

Returns true on success

=head2 parse_dates( $SCALAR )

C<parse_dates> is expecting a scalar that has a newline separated list of
dates.  The text can contain any of the following:

=over

=item A holiday known to L<DateTime::Event::Holiday::US>

=item A RRULE -- L<DateTime::Format::ICal> is being used to parse this input

=item A formatted, or partially formatted, date string --
L<DateTime::Format::Flexible> is being used to parse this input.

=back

Returns true on success or false on failure.

Any line that is not recognized is silently ignored.  Check C<bad_format> for
a list of unknown formats.

=head2 bad_format

Returns a reference to an array of unrecognized formats.

=head2 add

C<add> expects a single integer greater than or equal to 0 (though 0 would be
kind of useless).

This is the number of days into the future you are looking for.

The C<start_date> and C<days_to_skip> values need to have been populated or
this method will croak.

In array context a reference to a L<DateTime::Span> object and
a L<DateTime::SpanSet> object is returned, otherwise a reference to a hash with
those objects as values is returned.

X<DateTime>
X<DateTime::Duration>

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Alan Young <harleypig@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alan Young.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

