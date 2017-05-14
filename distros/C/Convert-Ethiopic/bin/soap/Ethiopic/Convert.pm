package Ethiopic::Convert;


BEGIN
{
	use strict;
	use vars qw($VERSION);

	use SafePaths;

	$VERSION = '0.10';

	require 5.000;

	use Convert::Ethiopic;
	require Convert::Ethiopic::System;
	require Convert::Ethiopic::Number;
	require Convert::Ethiopic::Date;
	require Convert::Ethiopic::String;
}



sub number
{
shift;

	my $self = new Convert::Ethiopic::Number;

	#
	# set defaults if unset:
	#
	$self->{sysOut} = new Convert::Ethiopic::System ( "UTF8" );
		# unless ( $self->{sysOut} );

	#
	# reset string if we've been passed one:
	#
	$self->number ( @_ ) if ( @_ );

	$self->_convert;
}


sub string
{
shift;

	my $i = new Convert::Ethiopic::System ( "sera" );

	#
	#  make sure this is also the default
	#
	my $o = new Convert::Ethiopic::System ( "UTF8" );

	my $self = new Convert::Ethiopic::String ( $i, $o );


	$self->string ( $_[0] );

	$self->convert;
}


sub date
{
shift;

	my $self = new Convert::Ethiopic::Date ( @_ );

	my $conv = $self->toEthiopic;
	
	[ $conv->{date}, $conv->{month}, $conv->{year} ];
}
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

Ethiopic::Time - conversions of calendar systems to/from Ethiopic and Gregorian.

=head1 SYNOPSIS

  use LiveGeez::Request;
  require Convert::Ethiopic::Time;
  my $r = LiveGeez::Request->new;

	ReadParse ( \%input );
	$r->ParseInput ( \%input );

	my $t = Convert::Ethiopic::Time->new ( $r );

	$t->GregorianToEthiopic;

	print "$t->{euDay}/$t->{euMonth}/$t->{euYear} = ";
	print "$t->{etDay}/$t->{etMonth}/$t->{etYear}\n" 

=head1 DESCRIPTION

Ethiopic::Time and Ethiopic::Cstocs are designed as interfaces to the methods in the
Ethiopic:: module and is oriented as services for the LiveGeez:: module.  In this
version Ethiopic::Time expects to receive an object with hash elements using
the keys:

=over 4

=item 'calIn'

which can be "euro or "ethio".

=item  'date'

a comma separated list as "day,month,year".

=item 'LCInfo'

locale settings I<see the LibEth man pages>.

=back

These keys are set when using a LiveGeez::Request object as shown in the example.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

perl(1).  LiveGeez(3), L<http://libeth.netpedia.net|http://libeth.netpedia.net>

=cut
