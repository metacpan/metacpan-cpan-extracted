package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Data::_Cookies
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub cookie_deserialize
# /type method
# /effect ""
# //parameters
#	data
# //returns
#	?
 {
	my ($this) = @ARGUMENTS;

	return({}) unless (defined($_[SPX_DATA]));
	$_[SPX_DATA] =~ tr/+/ /;
	my $pairs = [split(qr{;\h*}, $_[SPX_DATA], PKY_SPLIT_RETURN_FULL_TRAIL)];

	my $settings = {};
	foreach my $pair (@$pairs)
	{
		my ($name, $value) = split ('=', $pair, 2);

		$this->url_decode($name);
		$this->url_decode($value);

		unless (exists($settings->{$name}))
		{
			$settings->{$name} = [];
		}
		push($settings->{$name}, $value);
	}

	return($settings);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.38
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
