package Date::Range::Birth;

use strict;
use vars qw($VERSION);
$VERSION = '0.02';

require Date::Range;
use base qw(Date::Range);

use Date::Calc;
use Date::Simple;

sub _croak { require Carp; Carp::croak(@_) }

sub new {
    my($class, $age, $date) = @_;
    $date ||= Date::Simple->new; # default today
    unless (UNIVERSAL::isa($date, 'Date::Simple')) {
	_croak("date should be given as Date::Simple object: $date");
    }

    my($start, $end);
    if (ref($age) && ref($age) eq 'ARRAY') {
	($start, $end) = $class->_from_array($age, $date);
    }
    elsif ($age =~ /^\d+$/) {
	($start, $end) = $class->_from_age($age, $date);
    } else {
	_croak("invalid argument for Date::Range::Birth: $age");
    }
    return $class->SUPER::new($start, $end);
}

sub _from_age {
    my($class, $age, $date) = @_;

    my @start = Date::Calc::Add_Delta_YMD(_ymd($date),  -$age - 1, 0, 1);
    my @end   = Date::Calc::Add_Delta_YMD(_ymd($date),  -$age, 0, 0);

    return Date::Simple->new(@start), Date::Simple->new(@end);
}

sub _from_array {
    my($class, $age, $date) = @_;
    my @ages = sort { $a <=> $b } @$age;
    @ages == 2 or _croak("Date::Range::Birth: invalid number of args in age");

    # old's start to young's end
    my @start = Date::Calc::Add_Delta_YMD(_ymd($date),  -$ages[1] - 1, 0, 1);
    my @end   = Date::Calc::Add_Delta_YMD(_ymd($date),  -$ages[0], 0, 0);

    return Date::Simple->new(@start), Date::Simple->new(@end);
}

sub _ymd {
    my $date = shift;
    return $date->year, $date->month, $date->day;
}

1;
__END__

=head1 NAME

Date::Range::Birth - range of birthday for an age

=head1 SYNOPSIS

  use Date::Range::Birth;

  # birthday for those who are 24 years old now
  my $range = Date::Range::Birth->new(24);

  # birthday for those who are 24 years old in 2001-01-01
  my $date   = Date::Simple->new(2001, 1, 1);
  my $range2 = Date::Range::Birth->new(24, $date);

  # birthday for those who are between 20 and 30 yeard old now
  my $range3 = Date::Range::Birth->new([ 20, 30 ]);

=head1 DESCRIPTION

Date::Range::Birth is a subclass of Date::Range, which provides a way
to construct range of dates for birthday.

=head1 METHODS

=over 4

=item new

  $range = Date::Range::Birth->new($age);
  $range = Date::Range::Birth->new($age, $date);
  $range = Date::Range::Birth->new([ $young, $old ]);
  $range = Date::Range::Birth->new([ $young, $old ], $date);

returns Date::Range::Birth object for birthday of the age. If C<$date>
(Date::Simple object) provided, returns range of birthday for those
who are C<$age> years old in C<$date>. Default is today (now).

If the age is provided as array reference (like C<[ $young, $old ]>),
returns range of birthday for those who are between C<$young> -
C<$old> years old. It may be handy for searching teenagers, etc.

=back

Other methods are inherited from Date::Range. See L<Date::Range> for
details.

=head1 EXAMPLE

Your customer database schema:

  CREATE TABLE customer (
      name     varchar(64) NOT NULL,
      birthday date NOT NULL
  );

What you should do is to select name and birthday of the customers who are
2X years old (between 20 and 29).

  use DBI;
  use Date::Range::Birth;

  my $dbh = DBI->connect( ... );
  my $range = Date::Range::Birth->new([ 20, 29 ]);

  my $sth = $dbh->prepare(<<'SQL')
  SELECT name, birthday FROM customer WHERE birthday >= ? AND birthday <= ?
  SQL

  # Date::Simple overloads to 'yyyy-mm-dd'!
  $sth->execute($range->start, $range->end);

  while (my $data = $sth->fetchrow_arrayref) {
      print "name: $data->[0] birthday: $data->[1]\n";
  }
  $dbh->disconnect;

=head1 AUTHOR

Original idea by ikechin E<lt>ikebe@cpan.orgE<gt>

Code implemented by Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Date::Range>, L<Date::Simple>, L<Date::Calc>

=cut
