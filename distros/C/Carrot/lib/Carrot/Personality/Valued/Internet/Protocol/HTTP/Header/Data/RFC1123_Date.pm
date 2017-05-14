package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Data::RFC1123_Date
# /type class
# //parent_classes
#	::Personality::Valued::Internet::Protocol::HTTP::Header::Data::_Scalar
# /capability ""
{
	warn('#FIXME: looks like this could now be found in ::Valued::Time');

	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $epoch_time = '::Individuality::Singular::Process::Epoch_Time');

# =--------------------------------------------------------------------------= #

sub assign_value
# /type method
# /effect ""
# //parameters
#	date
# //returns
{
	my ($this, $date) = @ARGUMENTS;

	if ($date =~ m{^(\+|\-)}s)
	{
		my $seconds = symbolic_duration_to_seconds($date) || 0;
		$seconds += time;
		$date = seconds_to_rfc1123_date($seconds);
	} elsif ($date =~ m{^\d+$}s)
	{
		$date = seconds_to_rfc1123_date($date);
	}
	$$this = $date;
	return;
}

sub set_current
# /type method
# /effect ""
# //parameters
# //returns
{
	${$_[THIS]} = seconds_to_rfc1123_date($$epoch_time);
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.56
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
