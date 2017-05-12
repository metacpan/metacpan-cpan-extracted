package DateTime::Calendar::WarwickUniversity;

=head1 NAME

DateTime::Calendar::WarwickUniversity - Warwick University academic calendar

=head1 SYNOPSIS

  use DateTime::Calendar::WarwickUniversity;

  my $dt = DateTime::Calendar::WarwickUniversity->new(
  	year  => 2007,
  	month => 01,
  	day   => 8,
  );

  # 15
  print $dt->academic_week;

  # 11
  print $dt->term_week;

  # 2, 1
  print join(', ', $dt->term_and_week);

=head1 DESCRIPTION

DateTime::Calendar::WarwickUniversity is used for working with the
academic calendar in use at the University of Warwick.

=cut

use 5.008004;
use strict;
use warnings;

use Carp;
use DateTime::Event::WarwickUniversity;
use base 'DateTime';

our $VERSION = '0.02';

=head2 academic_week

Takes no argument.

Returns the academic week for the current object, in the range 1..53.

=cut

sub academic_week {
	my $self = shift;

	my $start = DateTime::Event::WarwickUniversity
			->new_year_for_academic_year($self);

	# TODO: Check whether the 53 and 1 are always valid.
	return $self->week_number - $start->week_number
		+ ($self->week_year > $start->week_year ? 53 : 1);
}

=head2 term_and_week

Takes no argument.

Returns a list ($term, $week) for the current object.
$term is either in the range 1..3, or one of 'C', 'E' or 'S', representing
the Christmas, Easter and Summer holidays.
$week is in the range 1..10.

=cut

sub term_and_week {
	my $self = shift;

	my $academic_week = $self->academic_week;

	# TODO: Check these assumptions.
	if ($academic_week <= 10) {
		return (1, $academic_week);
	} elsif ($academic_week <= 14) {
		return ('C', $academic_week - 10);
	} elsif ($academic_week <= 24) {
		return (2, $academic_week - 14);
	} elsif ($academic_week <= 29) {
		return ('E', $academic_week - 24);
	} elsif ($academic_week <= 39) {
		return (3, $academic_week - 29);
	} else {
		return ('S', $academic_week - 39);
	}
}

=head2 term_week

Takes no argument.

Returns the term week for the current object, in the range 1..30, or undef if
the date does not fall within a term week.

=cut

sub term_week {
	my $self = shift;

	my ($term, $week) = $self->term_and_week;

	if ($term == 1 or $term == 2 or $term == 3) {
		return ($term - 1) * 10 + $week;
	} else {
		return undef;
	}
}

1;
__END__

=head1 SEE ALSO

L<DateTime>, L<DateTime::Event::WarwickUniversity>

=head1 AUTHOR

Tim Retout E<lt>tim@retout.co.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2006, 2007 by Tim Retout

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
