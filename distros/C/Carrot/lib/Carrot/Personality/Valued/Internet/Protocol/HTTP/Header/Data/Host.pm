package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Data::Host
# /type class
# //parent_classes
#	::Personality::Recursive::Internet::Protocol::HTTP::Common::Header_Lines::_Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	
# =--------------------------------------------------------------------------= #

sub set
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	my ($this) = @ARGUMENTS;

	$$this = $_[SPX_VALUE];
	$$this =~ s{:80$}{}s;

	my $port = (($$this =~ s{(:\d{1,5})$}{}s) ? $1 : '');
	$$this =~ s{[^a-z0-9\-\.]}{}si;
	$$this .= $port;

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.42
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
