package Convert::Ethiopic::Cstocs;

$VERSION = '0.10';

require 5.000;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
			EthiopicNumber
			);

use Convert::Ethiopic;
require HTML::Entities;


#------------------------------------------------------------------------------#
#
# "EthiopicNumber"
#
#	Takes system, number, and image-path (if used) arguments and returns the
#	converted numeric sequence.  The the font system does not contain Ethiopic
#	numerals images will be used instead.
#
#------------------------------------------------------------------------------#
sub EthiopicNumber
{
my $r = shift;


	local ( $sysOut ) = ( $r->{sysOut}->HasENumbers ) 
					  ? $r->{sysOut}->{sysNum} : $image;

	local ( $eNumber ) = ArabToEthiopic (
		$r->{number},
		$r->{sysOut}->{sysNum},
		$r->{sysOut}->{xferNum},
		$r->{sysOut}->{fontNum},
		$r->{sysOut}->{iPath}
	);

	$eNumber =~ s/img/img border=0/g if ( $sysNum eq $image );  

	return ( HTML::Entities::encode($eNumber, "\200-\377") )
		if ( $r->{sysOut}->{'7-bit'} );

	$eNumber;

}


sub new
{
my $class      = shift;
my ($in, $out) = (shift, shift);

$fntext = ' sub {
	local ( $eString ) = ConvertEthiopicString (
		$_[0],
		$in->{sysNum},
		$in->{xferNum},
		$out->{sysNum},
		$out->{xferNum},
		$out->{fontNum},
		$out->{langNum},
		$out->{iPath},
		$out->{options},
		1,  #  closing
	);

	$eString = HTML::Entities::encode($eString, "\200-\377")
			   if ( $out->{\'7-bit\'} );

	return $eString; }';

	my $fn = eval $fntext;
	bless $fn, $class;

	$fn;

}


sub conv
{
my $self = shift;
	return &$self($_[0]);
}
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

Ethiopic::Cstocs - conversions of charset encodings for Ethiopic script

=head1 SYNOPSIS

  use LiveGeez::Request;
  require Convert::Ethiopic::Cstocs;
  my $r = LiveGeez::Request->new;

	ReadParse ( \%input );
	$r->ParseInput ( \%input );

	my $c = Convert::Ethiopic::Cstocs->new ( $r );

	print &$c ("`selam:");
	print $c->conv("`alem"), "\n";

	$r->{number} = 1991;

	print "The Year in Ethiopia is ", EthiopicNumber ( $r ), "\n";

=head1 DESCRIPTION

Ethiopic::Cstocs and Ethiopic::Time are designed as interfaces to the methods in the
Ethiopic:: module and is oriented as services for the LiveGeez:: module.  In this
version Ethiopic::Cstocs expects to receive an object with hash elements using
the keys:

'sysInNum', 'xferInNum', 'sysOutNum', 'xferOutNum', 'fontOutNum',
'langNum', 'iPath', 'options', '7-bit', and 'number' if a numeral
system conversion is being performed.

These keys are set when using a LiveGeez::Request object as shown in the example.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

perl(1).  LiveGeez(3).  L<http://libeth.netpedia.net|http://libeth.netpedia.net>

=cut
