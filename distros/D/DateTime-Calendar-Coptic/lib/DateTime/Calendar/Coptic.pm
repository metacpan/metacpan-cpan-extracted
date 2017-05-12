package DateTime::Calendar::Coptic;
use base qw( DateTime::Calendar::CopticEthiopic );

BEGIN
{
use vars qw(
		$VERSION
		$n
	);

	$VERSION = "0.03";

	require DateTime::Calendar::Coptic::Language;

	require Convert::Number::Coptic;
	$n = new Convert::Number::Coptic;

}

sub new
{
my $class = shift;
my %args  = @_ if ($#_);
my $language = "cop";

	my $self;

	if ( $args{language} ) {
		$language = $args{language};
		delete ( $args{language} );
	}
	if ( $args{calscale} ) {
		if ( $args{calscale} =~ /gregorian/i ) {
			#
			# We have been given dates in the Gregorian system
			# so we must convert into Coptic
			#
			my $dt = {}; bless $dt, $class;
			if ( $args{day} && $args{month} && $args{year} ) {
				( $args{day}, $args{month}, $args{year} )
				= $dt->fromGregorian ( $args{day}, $args{month}, $args{year} );
			}
			else {
			 	die ( "Useless Gregorian context, no date args passed.\n" );
			}
		}
		elsif ( $args{calscale} =~ /copticpic/i ) {
			$args{year} -= 276;
		}
		delete ( $args{calscale} );
	}

	$self = new DateTime ( %args );

	if ( ref($language) ) {
		$self->{language} = $language;
	}
	else {
		# print "Loading $language\n";
		$self->{language} = DateTime::Calendar::Coptic::Language->new ( language => $language );
	}

	my $blessing = bless ( $self, $class );

	$self->{rd} = $self->_EthiopicToAbsolute;

	$blessing;
}

sub from_object
{
	my ( $class ) = shift;
	my %args = validate( @_,
		{
			object => {
				type => OBJECT,
				can => 'utc_rd_values',
			},
		},
	);

	my $object = $args{ object }->clone();
	$object->set_time_zone( 'floating' ) if $object->can( 'set_time_zone' );  

	my ( $rd, $rd_secs ) = $object->utc_rd_values();

	my $self = bless( { rd => $rd, rd_secs => $rd_secs }, $class );

	$self;
}


sub epoch
{
        103605;
}

sub utc_rd_values
{
my ($self) = @_;

	( $self->{rd}, $self->{rd_secs} || 0 );
}


#
# calscale and toGregorian and are methods I recommend every non-Gregorian
# based DateTime package provide to identify itself and to convert the
# calendar system it handles into a normalized form.
#
sub calscale
{
	"coptic";
}


sub _sep
{
	", ";
}


sub _daysep
{
	" exoou "
}


sub ad
{
	"AD"
}


sub full_date
{
my ($self) = shift;

	(@_)
	?
	$self->day_name.$self->_sep.$self->month_name." ".$n->convert($self->day).$self->_daysep.$n->convert($self->year)." ".$self->ad
	:
        ( $self->{_trans} )
	  ?
	  $self->day_name(@_).$self->_sep.$self->month_name(@_)." ".$self->day.$self->_daysep.$self->year." ".$self->ad(@_)
	  :
	  $self->day_name.$self->_sep.$self->month_name." ".$self->day.$self->_daysep.$n->convert($self->year)." ".$self->ad
	;
}


sub long_date
{
my ($self) = shift;

	(@_)
	?
	$n->convert($self->day)."-".$self->month_name."-".$n->convert($self->year)
        :
	( $self->{_trans} )
	  ?
	  $self->day."-".$self->month_name(@_)."-".$self->year
	  :
	  $self->day."-".$self->month_name."-".$n->convert($self->year)
	;
}


sub medium_date
{
my ($self) = @_;
	
	my $year = $self->year;
	$year =~ s/^\d\d//;

	($#_)
	?
	$self->day."-".$self->month_name."-".$n->convert($year)
	:
	( $self->{_trans} )
	  ?
	  $self->day."-".$self->month_name(@_)."-".$year
	  :
	  $n->convert($self->day)."-".$self->month_name."-".$n->convert($year)
	;
}


sub useTranscription
{
my $self = shift;

	$self->{_trans} = shift if (@_);

	$self->{_trans};
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

DateTime::Calendar::Coptic - DateTime Module for the Coptic Calendar System.

=head1 SYNOPSIS

 use DateTime::Calendar::Coptic;
 #
 #  typical instantiation:
 #
 my $coptic = new DateTime::Calendar::Coptic ( day => 28, month => 7, year => 1719 );

 #
 # Get Gregorian Date:
 #
 my ($d,$m,$y) = $coptic->gregorian;

 #
 #  instantiate with a Gregorian date, date will be converted.
 #
 $coptic = new DateTime::Calendar::Coptic ( day => 5, month => 4, year => 2003, calscale => 'gregorian' );

 #
 #  get a DateTime object in the Gregorian calendar system
 #
 my $grego = $coptic->toGregorian;  

=head1 DESCRIPTION

The DateTime::Calendar::Coptic module provides methods for accessing date information
in the Coptic calendar system.  The module will also convert dates to
and from the Gregorian system.

=head1 CREDITS

L<http://www.copticchurch.net/easter.html>

=head1 REQUIRES

DateTime and L<Convert::Number::Coptic>.  It should work with
any version of Perl.  L<Convert::Number::Coptic> is only required
if you want to display years and days in Coptic numerals.

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 BUGS

None presently yet.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<DateTime>

=cut
