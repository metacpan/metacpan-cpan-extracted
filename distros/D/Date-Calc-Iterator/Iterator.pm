package Date::Calc::Iterator;

# $Id: Iterator.pm,v 1.2 2004/03/17 19:44:40 bronto Exp $

use 5.006;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '1.00';

use Date::Calc qw(Delta_Days Add_Delta_Days) ;

sub new {
  my $self  = shift ;
  my %parms = @_ ;

  my $class = ref $self || $self ;

  die "Need a start date" unless exists $parms{from} and ref $parms{from} eq 'ARRAY' ;
  die "Need an end date"  unless exists $parms{to}   and ref $parms{to}   eq 'ARRAY' ;
  die "Need an integer step"  if exists $parms{step} and not $parms{step} =~ /^\d+$/ ;

  _check_date($parms{from}) or die "Invalid start date" ;
  _check_date($parms{to})   or die "Invalid end date" ;

  $parms{step}     = 1 unless exists $parms{step} ;
  $parms{delta}    = 0 ;
  $parms{maxdelta} = Delta_Days(@{$parms{from}},@{$parms{to}}) ;

  my @object_keys = qw(from to step delta maxdelta) ;
  my %object_hash ;
  @object_hash{@object_keys} = @parms{@object_keys} ;
  return bless \%object_hash,$class ;
}

sub next {
  my $self = shift ;

  eval { $self->isa('Date::Calc::Iterator') } ;
  die "next() is an object method" if $@ ;

  return undef if $self->{delta} > $self->{maxdelta} ;

  my @next_date = Add_Delta_Days(@{$self->{from}},$self->{delta}) ;
  $self->{delta} += $self->{step} ;
  return wantarray ? @next_date : \@next_date ;
}

sub _check_date {
  my $date = shift ;
  my ($y,$m,$d) = @$date ;

  return undef unless $y =~ /^\d+$/ ;
  return undef unless $m =~ /^\d{1,2}$/ and $m >= 1 and $m <= 12 ;
  return undef unless $d =~ /^\d{1,2}$/ and $d >= 1 and $d <= 31 ;
}

1;
__END__

=head1 NAME

Date::Calc::Iterator - Iterate over a range of dates

=head1 SYNOPSIS

  use Date::Calc::Iterator;

  # This puts all the dates from Dec 1, 2003 to Dec 10, 2003 in @dates1
  # @dates1 will contain ([2003,12,1],[2003,12,2] ... [2003,12,10]) ;
  my $i1 = Date::Calc::Iterator->new(from => [2003,12,1], to => [2003,12,10]) ;
  my @dates1 ;
  push @dates1,$_ while $_ = $i1->next ;

  # Adding an integer step will iterate with the specified step
  # @dates2 will contain ([2003,12,1],[2003,12,3] ... ) ;
  my $i2 = Date::Calc::Iterator->new(from => [2003,12,1], to => [2003,12,10], step => 2) ;
  my @dates2 ;
  push @dates2,$_ while $_ = $i2->next ;


=head1 ABSTRACT

Date::Calc::Iterator objects are used to iterate over a range of
dates, day by day or with a specified step. The method next() will
return each time an array reference containing ($year,$month,$date)
for the next date, or undef when finished.

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
as array references:

  $i = Date::Calc::Iterator->new( from => [2003,12,1], to => [2003,12,10] )

C<from> and C<to> are, obviously, required.

Optionally, you can specify a custom step with the C<step> key, for example:

  $i = Date::Calc::Iterator->new( from => [2003,12,1], to => [2003,12,31],
                            step => 7 ) ;

will iterate on December 2003, week by week, starting from December 1st.


=head2 next

Returns the next date; in list context it returns an array containing
year, month and day in this order, or C<undef> if iteration is over;
in scalar context, it returns a reference to that array, or C<undef>
if iteration is over.

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.22 with options

  -CAX
	-b
	5.6.0
	--use-new-tests
	--skip-exporter
	-O
	-v
	0.01
	Date::Calc::Iterator

=back



=head1 SEE ALSO

The wonderful Date::Calc module, on top of which this module is made.

DateTime::Event::Recurrence and all the DateTime family from
L<http://datetime.perl.org>. 


=head1 AUTHOR

Marco Marongiu, E<lt>bronto@cpan.orgE<gt>

=head1 THANKS

Thanks to Steffen Beyer, for writing his Date::Calc and for allowing
me to use his namespace.

Blame on me, for being so lazy (or spare-time-missing) that I didn't
make this module compatible with the Date::Calc::Object interface.


=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Marco Marongiu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
