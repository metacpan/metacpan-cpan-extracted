package Carrot::Personality::Valued::Time::Symbolic_Duration
# /type class
# //parent_classes
#	::Personality::Elemental::Scalar::Textual
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $syntax_re = '^(\+|-|)(\d+)\h*(s|m|h|d|w)(?:econds?|inutes?|ours?|ays?|eeks?)?\h*';

# =--------------------------------------------------------------------------= #

sub import_textual_value
# /type method
# /effect "Verifies the parameter"
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return($_[SPX_VALUE] =~ m{[$syntax_re]*}so);
}

sub symbolic_duration_to_seconds
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my $seconds = 0;
	my $value = ${$_[THIS]};
	while ($value =~ s{$syntax_re}{}sio)
	{
		if ($3 eq 's')
		{
			$seconds += $2 * (($1 eq '-') ? -1 : 1);
		} elsif ($3 eq 'm')
		{
			$seconds += $2 *60 * (($1 eq '-') ? -1 : 1);
		} elsif ($3 eq 'h')
		{
			$seconds += $2 *3600 * (($1 eq '-') ? -1 : 1);
		} elsif ($3 eq 'd')
		{
			$seconds += $2 *86400 * (($1 eq '-') ? -1 : 1);
		} elsif ($3 eq 'w')
		{
			$seconds += $2 *7*86400 * (($1 eq '-') ? -1 : 1);
		}
	}

	return(IS_UNDEFINED) if ($value));
	return($seconds);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.55
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
