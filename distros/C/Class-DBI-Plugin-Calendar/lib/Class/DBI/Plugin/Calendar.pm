package Class::DBI::Plugin::Calendar;
#use 5.008006;
use strict;
use warnings FATAL => 'all';

use Carp;
use Calendar::Simple ();
use Time::Piece;
use Class::DBI::Plugin::Calendar::Day;

our $VERSION = '0.18';

sub import {
	my ($self, $date_field) = @_;

		# we require that they pass a $date_field
	croak __PACKAGE__." requires a date field to be passed to import() (aka use())" unless $date_field;
	
	my $caller = caller();
	no strict 'refs';

		# add some SQL to the calling class, as requested
	$caller->set_sql(calendar => <<"");
		SELECT *
		FROM __TABLE__
		%s
		ORDER BY `$date_field`


		# add the calendar method to the calling class
	*{"$caller\::calendar"} = sub {
		my($class,$month,$year,$mondays) = @_;

			# generate default values if necessary
		unless($month and $year) {
			my @lt = localtime;
			$month ||= sprintf '%02d', $lt[4] + 1;
			$year  ||= sprintf '%02d', $lt[5] + 1900;
		}

			# mysql required (for now?)
		my $where = qq[ WHERE MONTH(`$date_field`) = '$month' AND YEAR(`$date_field`) = '$year' ];

			# get the objects which are within the chosen month
		my @objects = $class->sth_to_objects($class->sql_calendar($where));
			
			# get the calendar layout for this month
			# map the dates to day objects:
			#
		my @weeks = Calendar::Simple::calendar($month,$year,$mondays);
		for my $week (@weeks) {
			for my $day (@$week) {
				$day ||= 0;
				my @events = ();
				while(@objects and $objects[0]->$date_field->mday == $day) {
					push @events, shift @objects;
				}
				my $date = $day
						? Time::Piece->strptime(join('-',$year,sprintf('%02d', $month),sprintf('%02d', $day)),'%Y-%m-%d')
						: undef;
				$day = Class::DBI::Plugin::Calendar::Day->new($date,\@events);
			}
		}
		return @weeks;
	};
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Class::DBI::Plugin::Calendar - Simple Calendar Support for Class::DBI

=head1 SYNOPSIS

  package DB;
  use base 'Class::DBI';
  use Class::DBI::Plugin::Calendar qw(date_fieldname);

  # the same as Calendar::Simple::calendar
  my @curr      = DB->calendar;             # get current month
  my @this_sept = DB->calendar(9);          # get 9th month of current year
  my @sept_2002 = DB->calendar(9, 2002);    # get 9th month of 2002
  my @monday    = DB->calendar(9, 2002, 1); # week starts with Monday

=head1 DESCRIPTION

Please note that this module only works with mysql at this point, as 
far as I know. Retrieve the objects in useful calendar-like data 
structures, similar to Calendar::Simple.

=head2 my @weeks = calendar([$month,$year,$monday])

@weeks holds arefs of 7 days each (there are dummy placeholders where needed), 
which are represented by Class::DBI::Plugin::Calendar::Day objects. Please
refer to the Class::DBI::Plugin::Calendar::Day perldoc for instructions.

=head1 SEE ALSO

Class::DBI, Calendar::Simple, Class::DBI::Plugin::Calendar::Day

=head1 AUTHOR

James Tolley, E<lt>james@bitperfect.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by James Tolley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
