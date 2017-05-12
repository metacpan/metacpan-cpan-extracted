package Date::Holidays::NO;

use vars qw($VERSION);

$VERSION=0.2;

use base qw(Date::Holidays::Abstract);
use No::Dato qw(helligdag helligdager);

sub holidays {
	my $year=shift;
	my @days=helligdager($year);
	my %days;
	foreach my $day (@days) {
		my ($month,$day, $text)=$day=~m/\d{4}-(\d{2})-(\d{2})\s*(.*)$/;
		$days{"$month$day"}=$text
	}
	return \%days;
};

sub is_holiday {
	my ($year,$month,$day)=@_;
	$month=($month<10 ?"0".$month : $month); 
	$day=($day<10 ?"0".$day :$day); 
	my $holiday=helligdag("$year-$month-$day");
	return $holiday if $holiday;
	return undef;
};

1;

__END__

=head1  NAME

Date::Holidays::NO - A wrapper for No::Dato to comply with Date::Holidays

=head1 SYNOPSIS

use Date::Holidays;

my $dh = Date::Holidays->new( countrycode => 'no' );

$dh->is_holiday( 2004, 12,  25); 
$dh->holidays( $year );

=head1 DESCRIPTION

This is just a wrapper around No::Dato to comply with the Date::Holidays 
factory class. See Date::Holidays for usage information, and No::Dato for
implementation details.

=head1 METHODS

=over 4

=item holidays

takes a year, and returns a hashref of all the holidays for that year. 

=item is_holiday

Takes year/month/date as parameters, and returns the name of the holiday
if it's a holiday, or undef otherwise.

=back

=head1 BUGS

Please report issues via CPAN RT:

  http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Holidays-NO

or by sending mail to

  bug-Date-Holidays-NO@rt.cpan.org

=head1 AUTHOR

Marcus Ramberg, (mramberg) - E<lt>mramberg@cpan.orgE<gt>

=head1 COPYRIGHT

Date-Holidays-NO is (C) by Marcus Ramberg, (mramberg) 2004

Date-Holidays-NO is released under the artistic license

The distribution is licensed under the Artistic License, as specified
by the Artistic file in the standard perl distribution
(http://www.perl.com/language/misc/Artistic.html).

=cut
